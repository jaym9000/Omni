#!/bin/bash

# Test script for guest message limits
# This script tests that guest users are properly limited to 20 messages

echo "🧪 Testing Guest Message Limits"
echo "================================"

# Test constants
PROJECT_NAME="OmniAI"
SCHEME="OmniAI"

# Build the app first
echo "📱 Building the app..."
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$SCHEME" \
           -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
           -configuration Debug \
           build-for-testing > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "Test Steps to Verify Guest Limits:"
echo "1. Launch the app in the simulator"
echo "2. Click 'Continue as Guest'"
echo "3. Send 20 messages to verify:"
echo "   - Messages 1-19 should send successfully"
echo "   - The guest counter should increment each time"
echo "   - Message 20 should send successfully"
echo "   - Message 21 should trigger the upgrade alert"
echo ""
echo "Expected Behavior:"
echo "- Guest counter shows 'X/20 free messages'"
echo "- After 20 messages, an alert appears:"
echo "  'Upgrade to Continue'"
echo "  'You've used all 20 free messages. Please sign up to continue chatting with Omni.'"
echo ""
echo "To reset guest message count for testing:"
echo "1. Delete the app from the simulator"
echo "2. Reinstall and test again"
echo ""
echo "✨ Test script complete. Please manually verify the guest limits in the simulator."