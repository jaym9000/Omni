#!/bin/bash

echo "🧪 Testing OmniAI Chat API"
echo "=========================="

# Function URL
URL="https://aichat-265kkl2lea-uc.a.run.app"

# Test message
MESSAGE="Hello, can you help me manage stress?"
SESSION_ID="test-session-$(date +%s)"

echo ""
echo "📤 Sending test message..."
echo "   Message: $MESSAGE"
echo "   Session: $SESSION_ID"
echo ""

# Send request
RESPONSE=$(curl -s -X POST "$URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"$MESSAGE\",
    \"sessionId\": \"$SESSION_ID\"
  }")

# Check response
if echo "$RESPONSE" | grep -q '"response"'; then
  echo "✅ Chat API is working!"
  echo ""
  echo "Response:"
  echo "$RESPONSE" | python3 -m json.tool | head -20
else
  echo "❌ Chat API failed"
  echo "Response: $RESPONSE"
fi