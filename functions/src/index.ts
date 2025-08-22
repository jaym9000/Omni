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

          // Check if user is guest and enforce limits
          let isGuest = isAnonymous;
          let userData: Record<string, unknown> = {};
          let guestMessageCount = 0;
          let maxGuestMessages = 20; // Total messages, not daily

          // Only try to fetch user data if we have a valid Firebase user ID
          if (userId && !userId.startsWith("guest_")) {
            try {
              const userDoc = await db.collection("users").doc(userId).get();
              if (userDoc.exists) {
                userData = userDoc.data() || {};
                isGuest = Boolean(userData?.isGuest) || isAnonymous;
                guestMessageCount = Number(userData?.guestMessageCount || 0);
                maxGuestMessages = Number(userData?.maxGuestMessages || 20);
              }
            } catch (error) {
              console.log("Could not fetch user data, treating as guest:", error);
              isGuest = true;
            }
          }

          // For guest users, check message limit
          if (isGuest) {
            console.log(`Guest user message count: ${guestMessageCount}/${maxGuestMessages}`);
            if (guestMessageCount >= maxGuestMessages) {
              response.status(429).json({
                error: "guest_limit_reached",
                message: `You've used all ${maxGuestMessages} free messages. Please sign up to continue.`,
                messagesUsed: guestMessageCount,
                maxMessages: maxGuestMessages,
              });
              return;
            }

            // Increment message count for guest users
            if (userId && !userId.startsWith("guest_")) {
              try {
                await db.collection("users").doc(userId).update({
                  guestMessageCount: admin.firestore.FieldValue.increment(1),
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
              } catch (error) {
                console.log("Could not update guest message count:", error);
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

- For simple questions (math, facts, etc.), give direct answers
- For emotional or mental health topics, be supportive and empathetic
- Don't force mental health context into unrelated conversations
- Keep responses concise and relevant to what was asked
- Only suggest professional help when truly appropriate
- Never provide medical advice or diagnoses

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
              messagesUsed: guestMessageCount + 1,
              messagesRemaining: Math.max(0, maxGuestMessages - (guestMessageCount + 1)),
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
