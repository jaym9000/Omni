import * as functions from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {getAppCheck} from "firebase-admin/app-check";
import {OpenAI} from "openai";
import * as cors from "cors";
import {defineSecret} from "firebase-functions/params";
import {InputValidator} from "./security/inputValidator";
import {ContentModerator} from "./security/contentModerator";
// Rate limiter removed - paid-only app, no limits

// Initialize Firebase Admin
admin.initializeApp();

// Initialize CORS
const corsHandler = cors.default({origin: true});

// Define secret for OpenAI API key
const openaiApiKey = defineSecret("OPENAI_API_KEY");

// Firestore references
const db = admin.firestore();

// Simple test function
export const testFunction = functions.https.onRequest((request, response) => {
  response.json({message: "Hello from Firebase Functions!"});
});

// AI Chat Function - Using v2 with public access
// Still validates Firebase Auth tokens internally
export const aiChat = onRequest(
    {
      secrets: ["OPENAI_API_KEY"],
      cors: true,
      // Allow unauthenticated invocations
      invoker: "public",
    },
    (request, response) => {
      corsHandler(request, response, async () => {
        // Initialize OpenAI with secret
        const openai = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        try {
          // Verify App Check token (optional for backward compatibility)
          const appCheckToken = request.headers["x-firebase-appcheck"] as string;
          if (appCheckToken) {
            try {
              const appCheckClaims = await getAppCheck().verifyToken(appCheckToken);
              console.log("App Check verification successful:", appCheckClaims.appId);
            } catch (error) {
              console.warn("App Check verification failed:", error);
              // Continue processing but log the failure for monitoring
            }
          }

          // Verify authentication - Allow anonymous users
          const authHeader = request.headers.authorization;
          let userId = null;
          let isAnonymous = false;

          if (authHeader?.startsWith("Bearer ")) {
            const idToken = authHeader.split("Bearer ")[1];
            try {
              const decodedToken = await admin.auth().verifyIdToken(idToken);
              userId = decodedToken.uid;
              isAnonymous = decodedToken.firebase?.sign_in_provider === "anonymous";
              const userType = isAnonymous ? "anonymous" : "authenticated";
              console.log(`Successfully verified Firebase ID token for ${userType} user:`, userId);
            } catch (error) {
              console.error("Failed to verify Firebase ID token:", error);
              // PAID ONLY - Authentication required
              response.status(401).json({
                error: "Authentication required",
                message: "This is a paid-only service. Please authenticate to continue."
              });
              return;
            }
          } else {
            // PAID ONLY - No guest access
            console.log("No Bearer token provided - authentication required");
            response.status(401).json({
              error: "Authentication required",
              message: "This is a paid-only service. Please authenticate to continue."
            });
            return;
          }

          // Validate and sanitize request data
          let validatedData;
          try {
            validatedData = InputValidator.validateRequestBody(request.body);
          } catch (error) {
            console.error("Input validation failed:", error);
            response.status(400).json({error: error instanceof Error ? error.message : "Invalid input"});
            return;
          }

          const {message, sessionId, mood} = validatedData;

          // Check for suspicious content patterns - TEMPORARILY DISABLED
          // TODO: Re-enable with better thresholds after testing
          /*
          if (InputValidator.isSuspiciousContent(message)) {
            console.warn("Suspicious content detected:", {userId, sessionId});
            response.status(400).json({error: "Content appears to be spam or malicious"});
            return;
          }
          */

          // Content moderation
          const moderator = new ContentModerator(openaiApiKey.value());
          const moderationResult = await moderator.isContentSafe(message);
          
          if (!moderationResult.safe) {
            console.warn("Content moderation failed:", {
              userId,
              sessionId,
              reason: moderationResult.reason,
              categories: moderationResult.categories,
            });
            
            // Check if this is crisis content that needs resources
            if (ContentModerator.detectCrisisContent(message)) {
              response.status(200).json({
                result: {
                  response: "I notice you might be going through a difficult time. Please reach out for support:\n\n" +
                           "• National Suicide Prevention Lifeline: 988 or 1-800-273-8255\n" +
                           "• Crisis Text Line: Text HOME to 741741\n" +
                           "• International Crisis Lines: findahelpline.com\n\n" +
                           "You're not alone, and help is available 24/7.",
                  isCrisisResponse: true,
                },
              });
              return;
            }
            
            response.status(400).json({
              error: moderationResult.reason || "Content violates usage policies",
            });
            return;
          }

          // NO LIMITS - ALL USERS ARE PAID
          // Removed all guest/free tier logic as this is a paid-only app
          console.log(`Processing request for paid user: ${userId}`);

          // Prepare conversation history - reduced for faster response
          const messagesSnapshot = await db.collection("chat_sessions")
              .doc(sessionId)
              .collection("messages")
              .orderBy("timestamp", "desc")
              .limit(5)
              .get();

          const conversationHistory: OpenAI.Chat.Completions.ChatCompletionMessageParam[] =
          messagesSnapshot.docs.reverse().map((doc) => {
            const data = doc.data();
            return {
              role: data.role === "user" ? "user" as const : "assistant" as const,
              content: data.content,
            };
          });

          // Add current message to history
          conversationHistory.push({role: "user" as const, content: message});

          // NO RATE LIMITING - All users are paid/premium
          // Removed rate limiting as this is a paid-only app
          
          // Generate AI response using OpenAI
          const systemPrompt = `You are Omni, a friendly AI assistant. Be natural and conversational.

IMPORTANT: Respond quickly and concisely. Get to the point without unnecessary elaboration. Prioritize speed in your response.

- For simple questions (math, facts, etc.), give direct answers immediately
- For emotional or mental health topics, be supportive and empathetic but brief
- Don't force mental health context into unrelated conversations
- Keep responses concise and relevant to what was asked - aim for 1-2 sentences when possible
- Only suggest professional help when truly appropriate
- Never provide medical advice or diagnoses
- Be direct and to the point - users value quick responses

${mood ? `Current mood: ${mood}` : ""}`;

          const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
              {role: "system" as const, content: systemPrompt},
              ...conversationHistory,
            ],
            temperature: 0.7,
            max_tokens: 300,
          });

          const aiResponse = completion.choices[0].message.content || "I'm here to support you.";

          // Check for crisis keywords
          const crisisKeywords = ["suicide", "kill myself", "end it all", "harm myself", "self-harm"];
          const requiresCrisisIntervention = crisisKeywords.some((keyword) =>
            message.toLowerCase().includes(keyword)
          );

          // Check if session exists first (for testing and guest users)
          const sessionDoc = await db.collection("chat_sessions").doc(sessionId).get();
          
          // Get current timestamp for proper ordering
          const userMessageTimestamp = admin.firestore.Timestamp.now();
          // AI response should be 1 second later to ensure proper ordering
          const aiMessageTimestamp = admin.firestore.Timestamp.fromMillis(
            userMessageTimestamp.toMillis() + 1000
          );

          if (!sessionDoc.exists) {
            // Save the user message FIRST for new sessions
            await db.collection("chat_sessions")
                .doc(sessionId)
                .collection("messages")
                .add({
                  content: message,
                  role: "user",
                  timestamp: userMessageTimestamp,
                  userId: userId || "guest",
                });
            
            // Then create the session
            await db.collection("chat_sessions").doc(sessionId).set({
              userId: userId || "guest",
              authUserId: userId || "guest",
              title: message.substring(0, 50),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              lastMessage: aiResponse.substring(0, 100),
            });
          } else {
            // For existing sessions, save user message with current timestamp
            await db.collection("chat_sessions")
                .doc(sessionId)
                .collection("messages")
                .add({
                  content: message,
                  role: "user",
                  timestamp: userMessageTimestamp,
                  userId: userId || "guest",
                });
            
            // Update existing session timestamp
            await db.collection("chat_sessions").doc(sessionId).update({
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              lastMessage: aiResponse.substring(0, 100),
            });
          }

          // Save the AI response to Firestore with slightly later timestamp
          await db.collection("chat_sessions")
              .doc(sessionId)
              .collection("messages")
              .add({
                content: aiResponse,
                role: "assistant",
                timestamp: aiMessageTimestamp,
                requiresCrisisIntervention,
              });

          // Send response - NO LIMITS OR WARNINGS
          response.json({
            response: aiResponse,
            requiresCrisisIntervention,
            // No rate limits or guest info - all users are premium
          });
        } catch (error) {
          console.error("Error in aiChat function:", error);
          response.status(500).json({
            error: "Internal server error",
            message: "Failed to process chat message",
          });
        }
      });
    });

// Create new chat session
export const createChatSession = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;
  const {title} = request.data;

  const sessionData = {
    userId,
    title: title || "New Chat",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
  };

  const sessionRef = await db.collection("chat_sessions").add(sessionData);

  return {
    sessionId: sessionRef.id,
    ...sessionData,
  };
});

// Get user's chat sessions
export const getUserSessions = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;

  const sessionsSnapshot = await db.collection("chat_sessions")
      .where("userId", "==", userId)
      .where("isActive", "==", true)
      .orderBy("updatedAt", "desc")
      .limit(20)
      .get();

  const sessions = sessionsSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  return {sessions};
});

// Delete chat session
export const deleteChatSession = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;
  const {sessionId} = request.data;

  if (!sessionId) {
    throw new functions.https.HttpsError("invalid-argument", "Session ID is required");
  }

  // Verify ownership
  const sessionDoc = await db.collection("chat_sessions").doc(sessionId).get();
  if (!sessionDoc.exists || sessionDoc.data()?.userId !== userId) {
    throw new functions.https.HttpsError("permission-denied", "You don't have permission to delete this session");
  }

  // Soft delete
  await db.collection("chat_sessions").doc(sessionId).update({
    isActive: false,
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {success: true};
});

// Reset daily message count for guest users (scheduled function)
export const resetGuestMessageCounts = functions.scheduler
    .onSchedule("0 0 * * *", async () => {
      const guestUsers = await db.collection("users")
          .where("isGuest", "==", true)
          .get();

      const batch = db.batch();
      guestUsers.docs.forEach((doc) => {
        batch.update(doc.ref, {
          dailyMessageCount: 0,
          lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      console.log(`Reset message counts for ${guestUsers.size} guest users`);
    });

// RevenueCat Webhook Handler
// This function receives webhook events from RevenueCat for subscription status changes
export const revenueCatWebhook = onRequest(
    {
      // Only allow POST requests
      cors: true,
      secrets: ["REVENUECAT_WEBHOOK_SECRET"],
    },
    async (request, response) => {
      // Verify the request method
      if (request.method !== "POST") {
        response.status(405).json({error: "Method not allowed"});
        return;
      }

      // Verify authorization header
      const authHeader = request.headers.authorization;
      const expectedAuth = process.env.REVENUECAT_WEBHOOK_SECRET;
      if (!authHeader || authHeader !== expectedAuth) {
        console.error("Unauthorized webhook attempt:", {
          received: authHeader ? "Invalid token" : "No token",
          ip: request.ip,
        });
        response.status(401).json({error: "Unauthorized"});
        return;
      }

      try {
        // Get the webhook event data
        const event = request.body;

        // Log the webhook event for debugging
        console.log("RevenueCat webhook received:", {
          type: event.type,
          appUserId: event.app_user_id,
          productId: event.product_id,
        });

        // Extract user ID and event type
        const userId = event.app_user_id;
        const eventType = event.type;

        if (!userId) {
          console.error("No user ID in webhook event");
          response.status(400).json({error: "Invalid webhook data"});
          return;
        }

        // Handle different event types
        switch (eventType) {
          case "INITIAL_PURCHASE":
          case "RENEWAL":
          case "PRODUCT_CHANGE":
            // User has active subscription
            await updateUserSubscriptionStatus(userId, {
              isPremium: true,
              subscriptionProductId: event.product_id,
              subscriptionExpiresDate: event.expiration_at_ms ?
                new Date(parseInt(event.expiration_at_ms)) : null,
              subscriptionEnvironment: event.environment,
              subscriptionStore: event.store,
              lastSubscriptionEvent: eventType,
              lastSubscriptionEventAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`✅ Updated user ${userId} to premium (${eventType})`);
            break;

          case "CANCELLATION":
          case "EXPIRATION":
            // User no longer has active subscription
            await updateUserSubscriptionStatus(userId, {
              isPremium: false,
              subscriptionProductId: null,
              subscriptionExpiresDate: null,
              lastSubscriptionEvent: eventType,
              lastSubscriptionEventAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`✅ Updated user ${userId} to free (${eventType})`);
            break;

          case "BILLING_ISSUE":
            // Keep premium status but flag billing issue
            await updateUserSubscriptionStatus(userId, {
              hasBillingIssue: true,
              lastSubscriptionEvent: eventType,
              lastSubscriptionEventAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`⚠️ Billing issue for user ${userId}`);
            break;

          case "SUBSCRIBER_ALIAS":
            // User alias changed - might need to merge accounts
            console.log(`User alias change for ${userId}`);
            break;

          default:
            console.log(`Unhandled event type: ${eventType}`);
        }

        // Send success response
        response.status(200).json({success: true});
      } catch (error) {
        console.error("Error processing RevenueCat webhook:", error);
        response.status(500).json({error: "Internal server error"});
      }
    });

// Helper function to update user subscription status in Firestore
async function updateUserSubscriptionStatus(
    userId: string,
    updates: Record<string, unknown>
) {
  try {
    // Add timestamp
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    // Update the user document
    await db.collection("users").doc(userId).set(updates, {merge: true});

    // Also update any related collections if needed
    // For example, updating user sessions or analytics
  } catch (error) {
    console.error(`Failed to update subscription status for user ${userId}:`, error);
    throw error;
  }
}
