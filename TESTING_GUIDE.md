# OmniAI Chat - Testing Guide 🚀

## ✅ All Issues Fixed!

The AI chat functionality is now fully operational. Here's what was fixed:

### Problems Resolved:
1. **Cloud Run Authentication** - Function now accepts requests with Firebase Auth validation
2. **Firestore Permissions** - Security rules updated to handle both authUserId and userId
3. **Data Consistency** - All code now uses Firebase Auth UID consistently
4. **Function Deployment** - Using Firebase Functions v2 with proper configuration

## 🧪 Testing the Chat

### 1. Launch the App
```bash
# Open the project in Xcode
open OmniAI.xcodeproj

# Or run from command line
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' \
  build && \
xcrun simctl launch booted com.jmjm.OmniAI
```

### 2. Sign In
- Launch the app
- Tap "Continue with Apple" or use email sign-in
- Complete the authentication flow

### 3. Test Chat
- Tap "Start New Chat" on the home screen
- Send a message like "Hello, how are you today?"
- You should receive an AI-powered response from OpenAI

### 4. Monitor Function Logs
```bash
# Watch real-time logs
firebase functions:log --only aiChat --follow

# Check recent logs
firebase functions:log --only aiChat --lines 50
```

## 🔍 Verification Checklist

### ✅ Function Health Check
```bash
# Test without auth (should return 401)
curl -X POST https://aichat-265kkl2lea-uc.a.run.app \
  -H "Content-Type: application/json" \
  -d '{"message":"test","sessionId":"test"}' 

# Expected: {"error":"Unauthorized - No Bearer token"}
```

### ✅ Firestore Indexes
```bash
# Check if indexes are deployed
firebase firestore:indexes
```

### ✅ OpenAI API Key
```bash
# Verify the secret is set
firebase functions:secrets:get OPENAI_API_KEY

# If not set, add it:
firebase functions:secrets:set OPENAI_API_KEY
```

## 📊 Expected Behavior

### When Everything Works:
1. **Chat Messages** - Real contextual AI responses (not fallback text)
2. **Response Time** - 1-3 seconds for AI response
3. **Guest Limits** - 5 messages/day for guest users
4. **Crisis Detection** - Appropriate resources for crisis keywords
5. **Session Persistence** - Chat history saved to Firestore

### Success Indicators in Logs:
```
✓ Successfully verified Firebase ID token for user: [uid]
✓ OpenAI API response received
✓ Message saved to Firestore
```

## 🐛 Troubleshooting

### If Chat Still Doesn't Work:

1. **Check Authentication**
   - Ensure user is signed in
   - Verify ID token is being generated
   - Check ChatService.swift line 258 for token retrieval

2. **Check Network**
   - Verify internet connection
   - Test function URL directly
   - Check for CORS issues

3. **Check Firestore**
   - Verify security rules are deployed
   - Check if chat_sessions collection exists
   - Ensure indexes are created

4. **Check Function**
   ```bash
   # Get function details
   firebase functions:list
   
   # Check function health
   curl -I https://aichat-265kkl2lea-uc.a.run.app
   ```

## 📱 Testing Different Scenarios

### Guest User Testing
1. Sign out completely
2. Tap "Continue as Guest"
3. Send 5 messages
4. 6th message should show upgrade prompt

### Crisis Response Testing
⚠️ Use with caution in production
```
Test message: "I'm feeling really anxious today"
Expected: Supportive response with coping strategies
```

### Session Management
1. Create multiple chat sessions
2. Switch between them
3. Verify history persists
4. Delete a session
5. Confirm it's removed

## 🎯 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Firebase Functions | ✅ Deployed | v2 with public invoker |
| Cloud Run | ✅ Configured | Accepts unauthenticated requests |
| Firestore Rules | ✅ Updated | Handles authUserId + userId |
| Firestore Indexes | ✅ Created | authUserId + updatedAt |
| iOS App | ✅ Updated | Sends Bearer token correctly |
| OpenAI Integration | ✅ Ready | Requires API key secret |

## 🚦 Quick Status Check

Run this command to verify everything:
```bash
./test-auth.sh
```

All tests should pass:
- Test 1: Returns "No Bearer token" ✅
- Test 2: Returns "Invalid Firebase ID token" ✅
- Test 3: Returns HTTP 401 (not 403) ✅

---

**Last Updated:** August 20, 2025
**Function URL:** https://aichat-265kkl2lea-uc.a.run.app
**Project ID:** omni-ai-8d5d2