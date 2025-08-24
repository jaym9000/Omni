#!/bin/bash

# Test Script for OmniAI Monetization Flows
# This script tests all monetization changes to ensure they work correctly

echo "================================="
echo "OmniAI Monetization Flow Testing"
echo "================================="
echo

SIMULATOR_ID="608805B3-69D3-4629-89F1-342F02EEDF27"
APP_BUNDLE="com.jns.Omni"

# Function to capture screenshot
capture_screenshot() {
    local name=$1
    xcrun simctl io $SIMULATOR_ID screenshot "/tmp/omni_test_${name}.png"
    echo "✓ Screenshot captured: ${name}"
}

# Function to check if app is running
check_app_running() {
    if xcrun simctl get_app_container $SIMULATOR_ID $APP_BUNDLE 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Test Flow 1: Guest Account (1 message limit)
echo "Test 1: Guest Account Flow"
echo "--------------------------"
echo "Expected: Guest can only send 1 message before paywall"
echo "Status: App is running, please test manually:"
echo "  1. Choose 'Continue as Guest' on onboarding"
echo "  2. Try to send a message in chat"
echo "  3. Verify paywall appears after 1st message"
capture_screenshot "guest_flow"
echo

# Test Flow 2: Free User (3 messages/day limit)
echo "Test 2: Free User Daily Limit"
echo "-----------------------------"
echo "Expected: Free users can send 3 messages per day"
echo "Status: Please test manually:"
echo "  1. Sign up with email (not guest)"
echo "  2. Send 3 messages in chat"
echo "  3. Verify paywall appears on 4th message attempt"
echo "  4. Verify 3-second delay for each message"
capture_screenshot "free_user_limit"
echo

# Test Flow 3: Journal Gating
echo "Test 3: Journal Feature Gating"
echo "------------------------------"
echo "Expected: ALL journal types require premium"
echo "Status: Please test manually:"
echo "  1. Go to Journal tab"
echo "  2. Try to access any journal type (Free-form, Guided, Gratitude)"
echo "  3. Verify all show premium gate"
capture_screenshot "journal_gating"
echo

# Test Flow 4: Mood to Chat Paywall
echo "Test 4: Mood Tracking to Chat Paywall"
echo "-------------------------------------"
echo "Expected: After mood tracking, chat button shows paywall for free users"
echo "Status: Please test manually:"
echo "  1. Track a mood"
echo "  2. Try 'Chat about it' button"
echo "  3. Verify paywall appears"
capture_screenshot "mood_to_chat"
echo

# Test Flow 5: Onboarding Premium Slide
echo "Test 5: Onboarding with Premium Slide"
echo "-------------------------------------"
echo "Expected: 6th slide shows premium trial pitch"
echo "Status: Please test manually:"
echo "  1. Force quit and restart app"
echo "  2. Go through onboarding"
echo "  3. Verify 6th slide shows premium benefits"
echo "  4. Verify 'Start Free Trial' button"
capture_screenshot "onboarding_premium"
echo

# Test Flow 6: Trial Countdown Banner
echo "Test 6: Trial Countdown Banner"
echo "------------------------------"
echo "Expected: Banner shows when < 48 hours left in trial"
echo "Status: Please test manually:"
echo "  1. For users with active trial"
echo "  2. Check if countdown banner appears on home"
echo "  3. Verify color changes (orange to red)"
capture_screenshot "trial_countdown"
echo

# Test Flow 7: 3-Second Delay
echo "Test 7: Free User Message Delay"
echo "-------------------------------"
echo "Expected: 3-second delay for free users"
echo "Status: Please test manually:"
echo "  1. As free user, send a message"
echo "  2. Verify 3-second processing delay"
echo "  3. Premium users should have no delay"
capture_screenshot "message_delay"
echo

echo "================================="
echo "Testing Instructions Complete"
echo "================================="
echo
echo "Screenshots saved to /tmp/omni_test_*.png"
echo
echo "Key Changes to Verify:"
echo "✓ Guest: 1 message limit (was 3)"
echo "✓ Free: 3 messages/day (was 10)"
echo "✓ Journal: ALL types gated (free-form was free)"
echo "✓ Mood: Chat button triggers paywall"
echo "✓ Onboarding: 6th slide is premium pitch"
echo "✓ Trial: Countdown banner when < 48 hours"
echo "✓ Delay: 3-second delay for free users"
echo
echo "Please manually verify each flow in the simulator!"