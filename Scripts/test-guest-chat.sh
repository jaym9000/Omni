#!/bin/bash

# Test script for guest/anonymous user chat functionality
# This script tests the AI Chat function with anonymous authentication

echo "🧪 Testing Guest/Anonymous Chat Flow"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function URL
FUNCTION_URL="https://aichat-265kkl2lea-uc.a.run.app"

# Test 1: Test without authentication (guest user)
echo -e "\n${YELLOW}Test 1: Guest user without token${NC}"
echo "Testing chat function without authentication..."

RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, I am a guest user testing the chat",
    "sessionId": "test-guest-session-001"
  }')

if echo "$RESPONSE" | grep -q '"response"'; then
  echo -e "${GREEN}✅ Guest user can chat without authentication${NC}"
  echo "Response: $(echo "$RESPONSE" | jq -r '.response' 2>/dev/null | head -c 100)..."
  
  if echo "$RESPONSE" | grep -q '"guestInfo"'; then
    echo "Guest info: $(echo "$RESPONSE" | jq '.guestInfo' 2>/dev/null)"
  fi
else
  echo -e "${RED}❌ Failed to get response for guest user${NC}"
  echo "Error: $RESPONSE"
fi

# Test 2: Test with Firebase anonymous auth token (if available)
echo -e "\n${YELLOW}Test 2: Anonymous Firebase user with token${NC}"
echo "Note: This test requires a valid anonymous Firebase token"
echo "You can get one by signing in anonymously in the app and checking the logs"

# Example token (you'll need to replace this with a real one)
# ANONYMOUS_TOKEN="YOUR_ANONYMOUS_TOKEN_HERE"

if [ -n "${ANONYMOUS_TOKEN:-}" ]; then
  echo "Testing with anonymous Firebase token..."
  
  RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANONYMOUS_TOKEN" \
    -d '{
      "message": "Hello, I am an anonymous Firebase user",
      "sessionId": "test-anonymous-session-001"
    }')
  
  if echo "$RESPONSE" | grep -q '"response"'; then
    echo -e "${GREEN}✅ Anonymous Firebase user can chat with token${NC}"
    echo "Response: $(echo "$RESPONSE" | jq -r '.response' 2>/dev/null | head -c 100)..."
    
    if echo "$RESPONSE" | grep -q '"guestInfo"'; then
      echo "Guest info: $(echo "$RESPONSE" | jq '.guestInfo' 2>/dev/null)"
    fi
  else
    echo -e "${RED}❌ Failed to get response for anonymous user${NC}"
    echo "Error: $RESPONSE"
  fi
else
  echo "Skipping test - no anonymous token provided"
fi

# Test 3: Test rate limiting for guest users
echo -e "\n${YELLOW}Test 3: Guest rate limiting${NC}"
echo "Testing if guest message limits are enforced..."

# This would need to be run multiple times to hit the limit
# For now, just check if the function returns guest info

RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Testing rate limits",
    "sessionId": "test-rate-limit-session"
  }')

if echo "$RESPONSE" | grep -q '"guestInfo"'; then
  echo -e "${GREEN}✅ Guest info is being tracked${NC}"
  MESSAGES_USED=$(echo "$RESPONSE" | jq -r '.guestInfo.messagesUsed' 2>/dev/null)
  MESSAGES_REMAINING=$(echo "$RESPONSE" | jq -r '.guestInfo.messagesRemaining' 2>/dev/null)
  echo "Messages used: $MESSAGES_USED"
  echo "Messages remaining: $MESSAGES_REMAINING"
else
  echo -e "${YELLOW}⚠️  No guest info in response (might be a regular user)${NC}"
fi

echo -e "\n${GREEN}✨ Test completed!${NC}"
echo "======================================"
echo ""
echo "Summary:"
echo "- Guest users should be able to chat without authentication"
echo "- Anonymous Firebase users should be able to chat with tokens"
echo "- Message limits should be tracked for guest users (20 total messages)"
echo ""
echo "To fully test the iOS app integration:"
echo "1. Launch the app and tap 'Continue as Guest'"
echo "2. Send a message in the chat"
echo "3. Check the Xcode console for logs"
echo "4. Verify you get an AI response (not just the fallback)"