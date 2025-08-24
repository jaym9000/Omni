import * as functions from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {OpenAI} from "openai";
import * as cors from "cors";
import {defineSecret} from "firebase-functions/params";

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
              // For guest users, allow fallback without authentication
              console.log("Allowing request without authentication for guest fallback");
              userId = `guest_${Date.now()}`; // Generate temporary ID for session
              isAnonymous = true;
            }
          } else {
            // No token provided - treat as guest
            console.log("No Bearer token provided - treating as guest user");
            userId = `guest_${Date.now()}`;
            isAnonymous = true;
          }

          // Get request data
          const {message, sessionId, mood} = request.body;

          if (!message || !sessionId) {
            response.status(400).json({error: "Missing required fields"});
            return;
          }

          // Check if user is guest/anonymous and enforce daily limits
          let isGuest = isAnonymous;
          let userData: Record<string, unknown> = {};
          let dailyMessageCount = 0;
          const maxDailyMessages = 3; // Reduced daily limit for aggressive monetization

          // Get current date (server time)
          const now = new Date();
          const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

          // Only try to fetch user data if we have a valid Firebase user ID
          if (userId && !userId.startsWith("guest_")) {
            try {
              const userDoc = await db.collection("users").doc(userId).get();
              if (userDoc.exists) {
                userData = userDoc.data() || {};
                isGuest = Boolean(userData?.isGuest) || isAnonymous;

                // Check if we need to reset daily count
                const lastMessageDateField = userData?.lastMessageDate as
                  admin.firestore.Timestamp | undefined;
                const lastMessageDate = lastMessageDateField?.toDate ?
                  lastMessageDateField.toDate() : null;

                if (lastMessageDate) {
                  const lastDate = new Date(lastMessageDate.getFullYear(),
                      lastMessageDate.getMonth(), lastMessageDate.getDate());

                  // If last message was on a different day, reset count
                  if (lastDate.getTime() !== today.getTime()) {
                    dailyMessageCount = 0;
                    // Reset the count in Firestore
                    await db.collection("users").doc(userId).update({
                      dailyMessageCount: 0,
                      lastMessageDate: admin.firestore.FieldValue.serverTimestamp(),
                    });
                  } else {
                    dailyMessageCount = Number(userData?.dailyMessageCount || 0);
                  }
                } else {
                  // First message ever
                  dailyMessageCount = 0;
                }
              }
            } catch (error) {
              console.log("Could not fetch user data, treating as guest:", error);
              isGuest = true;
            }
          }

          // For guest/free users, check daily message limit
          if (isGuest) {
            console.log(`Daily message count: ${dailyMessageCount}/${maxDailyMessages}`);

            if (dailyMessageCount >= maxDailyMessages) {
              // Calculate time until midnight for reset
              const tomorrow = new Date(today);
              tomorrow.setDate(tomorrow.getDate() + 1);
              const hoursUntilReset = Math.ceil((tomorrow.getTime() - now.getTime()) / (1000 * 60 * 60));

              response.status(429).json({
                error: "daily_limit_reached",
                message: `You've used all ${maxDailyMessages} free messages today. ` +
                  "Come back tomorrow or upgrade to premium for unlimited access!",
                dailyMessagesUsed: dailyMessageCount,
                maxDailyMessages: maxDailyMessages,
                resetInHours: hoursUntilReset,
              });
              return;
            }

            // Increment daily message count for guest users
            if (userId && !userId.startsWith("guest_")) {
              try {
                await db.collection("users").doc(userId).update({
                  dailyMessageCount: admin.firestore.FieldValue.increment(1),
                  lastMessageDate: admin.firestore.FieldValue.serverTimestamp(),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
              } catch (error) {
                console.log("Could not update daily message count:", error);
              }
            }
          }

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

          if (!sessionDoc.exists) {
            // Create the session if it doesn't exist (for testing/guest users)
            await db.collection("chat_sessions").doc(sessionId).set({
              userId: userId || "guest",
              authUserId: userId || "guest",
              title: message.substring(0, 50),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              lastMessage: aiResponse.substring(0, 100),
            });

            // Also save the user message for new sessions
            await db.collection("chat_sessions")
                .doc(sessionId)
                .collection("messages")
                .add({
                  content: message,
                  role: "user",
                  timestamp: admin.firestore.FieldValue.serverTimestamp(),
                  userId: userId || "guest",
                });
          } else {
            // Update existing session timestamp
            await db.collection("chat_sessions").doc(sessionId).update({
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              lastMessage: aiResponse.substring(0, 100),
            });
          }

          // Save the AI response to Firestore
          await db.collection("chat_sessions")
              .doc(sessionId)
              .collection("messages")
              .add({
                content: aiResponse,
                role: "assistant",
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                requiresCrisisIntervention,
              });

          // Send response
          response.json({
            response: aiResponse,
            requiresCrisisIntervention,
            guestInfo: isGuest ? {
              dailyMessagesUsed: dailyMessageCount + 1,
              dailyMessagesRemaining: Math.max(0, maxDailyMessages - (dailyMessageCount + 1)),
              maxDailyMessages: maxDailyMessages,
              isGuest: true,
            } : undefined,
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
