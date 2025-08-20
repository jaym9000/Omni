import * as functions from "firebase-functions";
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

// AI Chat Function
export const aiChat = functions.https.onRequest(
    {secrets: [openaiApiKey]},
    (request, response) => {
      corsHandler(request, response, async () => {
        // Initialize OpenAI with secret
        const openai = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        try {
          // Verify authentication
          const authHeader = request.headers.authorization;
          if (!authHeader?.startsWith("Bearer ")) {
            console.log("No Bearer token in Authorization header");
            response.status(401).json({error: "Unauthorized - No Bearer token"});
            return;
          }

          const idToken = authHeader.split("Bearer ")[1];
          let decodedToken;
          let userId;
          try {
            decodedToken = await admin.auth().verifyIdToken(idToken);
            userId = decodedToken.uid;
            console.log("Successfully verified Firebase ID token for user:", userId);
          } catch (error) {
            console.error("Failed to verify Firebase ID token:", error);
            response.status(401).json({error: "Invalid Firebase ID token"});
            return;
          }

          // Get request data
          const {message, sessionId, mood} = request.body;

          if (!message || !sessionId) {
            response.status(400).json({error: "Missing required fields"});
            return;
          }

          // Check if user is guest and enforce limits
          const userDoc = await db.collection("users").doc(userId).get();
          const userData = userDoc.data();
          const isGuest = userData?.isGuest || false;

          if (isGuest) {
            // Count today's messages for guest user
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            const messagesRef = db.collection("chat_sessions")
                .doc(sessionId)
                .collection("messages");

            const todayMessages = await messagesRef
                .where("userId", "==", userId)
                .where("timestamp", ">=", today)
                .where("role", "==", "user")
                .get();

            const messageCount = todayMessages.size;
            const maxMessages = 5;

            if (messageCount >= maxMessages) {
              response.status(429).json({
                error: "guest_limit_reached",
                message: "Daily message limit reached for guest users",
                messagesUsed: messageCount,
                maxMessages: maxMessages,
              });
              return;
            }
          }

          // Prepare conversation history
          const messagesSnapshot = await db.collection("chat_sessions")
              .doc(sessionId)
              .collection("messages")
              .orderBy("timestamp", "desc")
              .limit(10)
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
          const systemPrompt = `You are Omni, a compassionate and supportive AI mental health companion. 
Your role is to provide empathetic, non-judgmental support for users dealing with anxiety, depression, 
and other mental health challenges. 

Key guidelines:
- Be warm, understanding, and validating of emotions
- Use evidence-based therapeutic techniques (CBT, mindfulness, etc.)
- Never provide medical advice or diagnoses
- Encourage professional help when appropriate
- Detect crisis situations and provide appropriate resources
- Keep responses concise but meaningful (2-3 paragraphs max)
- Use a conversational, supportive tone

${mood ? `The user's current mood is: ${mood}` : ""}`;

          const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
              {role: "system" as const, content: systemPrompt},
              ...conversationHistory,
            ],
            temperature: 0.7,
            max_tokens: 500,
          });

          const aiResponse = completion.choices[0].message.content || "I'm here to support you.";

          // Check for crisis keywords
          const crisisKeywords = ["suicide", "kill myself", "end it all", "harm myself", "self-harm"];
          const requiresCrisisIntervention = crisisKeywords.some((keyword) =>
            message.toLowerCase().includes(keyword)
          );

          // Save user message to Firestore
          await db.collection("chat_sessions")
              .doc(sessionId)
              .collection("messages")
              .add({
                content: message,
                role: "user",
                userId: userId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                mood: mood || null,
              });

          // Save AI response to Firestore
          await db.collection("chat_sessions")
              .doc(sessionId)
              .collection("messages")
              .add({
                content: aiResponse,
                role: "assistant",
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                requiresCrisisIntervention,
              });

          // Update session timestamp
          await db.collection("chat_sessions").doc(sessionId).update({
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessage: aiResponse.substring(0, 100),
          });

          // Send response
          response.json({
            response: aiResponse,
            requiresCrisisIntervention,
            guestInfo: isGuest ? {
              messagesUsed: (userData?.dailyMessageCount || 0) + 1,
              messagesRemaining: Math.max(0, 5 - ((userData?.dailyMessageCount || 0) + 1)),
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
