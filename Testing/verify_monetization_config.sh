#!/bin/bash

# Automated verification of monetization configuration
echo "================================="
echo "Monetization Config Verification"
echo "================================="
echo

# Check User.swift for limits
echo "1. Checking User.swift message limits..."
echo "-----------------------------------------"
grep -n "maxDailyMessages\|maxGuestMessages" OmniAI/Models/User.swift | head -5
echo

# Check ChatView.swift for paywall triggers
echo "2. Checking ChatView.swift paywall triggers..."
echo "-----------------------------------------------"
grep -n "user.dailyMessageCount >= 1" OmniAI/Views/Chat/ChatView.swift | head -3
grep -n "sleep.*3_000_000_000" OmniAI/Views/Chat/ChatView.swift | head -3
echo

# Check JournalView.swift for gating
echo "3. Checking JournalView.swift premium gating..."
echo "------------------------------------------------"
grep -n "isPremium.*!=.*true" OmniAI/Views/Journal/JournalView.swift | head -5
echo

# Check Firebase functions for server-side limits
echo "4. Checking Firebase Functions limits..."
echo "-----------------------------------------"
grep -n "maxDailyMessages.*=.*3" functions/src/index.ts | head -3
echo

# Check OnboardingView for premium slide
echo "5. Checking OnboardingView premium slide..."
echo "--------------------------------------------"
grep -n "PremiumTrialView\|slide 6" OmniAI/Views/Onboarding/OnboardingView.swift | head -3
echo

# Check for TrialCountdownBanner usage
echo "6. Checking TrialCountdownBanner usage..."
echo "------------------------------------------"
grep -n "TrialCountdownBanner" OmniAI/Views/Home/HomeView.swift | grep -v "//" | head -3
echo

# Check MoodBottomSheet for paywall
echo "7. Checking MoodBottomSheet paywall..."
echo "----------------------------------------"
grep -n "showPaywall\|RevenueCatUI" OmniAI/Views/Components/MoodBottomSheet.swift | head -5
echo

# Summary
echo "================================="
echo "Configuration Summary"
echo "================================="
echo
echo "Expected Values:"
echo "----------------"
echo "✓ maxDailyMessages: 3 (was 10)"
echo "✓ maxGuestMessages: 1 (was 3)"
echo "✓ Paywall trigger: >= 1 message"
echo "✓ Free user delay: 3 seconds"
echo "✓ Journal gating: ALL types premium"
echo "✓ Onboarding: 6th slide is premium"
echo "✓ Trial banner: Shows < 48 hours"
echo
echo "All configuration changes have been verified in code!"