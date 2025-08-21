#!/bin/bash

# Test the AI Chat function with a mock Bearer token
echo "Testing AI Chat Function..."
echo "============================="
echo ""

# Test 1: Without any auth token (should fail)
echo "Test 1: No auth token"
curl -s -X POST https://aichat-265kkl2lea-uc.a.run.app \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","sessionId":"test-123"}' | jq .

echo ""

# Test 2: With invalid Bearer token (should fail with Firebase auth error)
echo "Test 2: Invalid Bearer token"
curl -s -X POST https://aichat-265kkl2lea-uc.a.run.app \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid-token-123" \
  -d '{"message":"Hello","sessionId":"test-123"}' | jq .

echo ""

# Test 3: Check if function is reachable
echo "Test 3: Function connectivity"
curl -s -I https://aichat-265kkl2lea-uc.a.run.app | head -5

echo ""
echo "============================="
echo "To test with a real Firebase ID token:"
echo "1. Run the iOS app in the simulator"
echo "2. Sign in with Apple or email"
echo "3. Try sending a chat message"
echo "4. Check 'firebase functions:log --only aiChat' for details"