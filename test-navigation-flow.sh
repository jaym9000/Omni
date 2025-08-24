#!/bin/bash

echo "Testing OmniAI Navigation Flow"
echo "=============================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if app is running
APP_PID=$(xcrun simctl spawn "iPhone 16 Pro" launchctl list | grep com.jns.Omni | awk '{print $1}')
if [ ! -z "$APP_PID" ]; then
    echo -e "${GREEN}✓ App is running (PID: $APP_PID)${NC}"
else
    echo -e "${RED}✗ App is not running${NC}"
    exit 1
fi

echo ""
echo "Expected Flow:"
echo "1. Splash Screen (auto-dismisses)"
echo "2. Welcome Screen → 'Get Started' button"
echo "3. Quick Setup → Select goal and mood"
echo "4. AI Preview → 'Start Your Free Trial' button"
echo "5. RevenueCat Paywall (Omni_Final)"
echo "6. After payment → PostTrialSignInView"
echo "7. After sign-in → MainTabView"

echo ""
echo -e "${YELLOW}Navigation Test Checklist:${NC}"
echo "□ Splash screen appears and auto-dismisses"
echo "□ Welcome screen shows with single CTA"
echo "□ Quick Setup allows goal and mood selection"
echo "□ Skip button is visible and not cut off"
echo "□ AI Preview shows personalized message"
echo "□ 'Start Your Free Trial' button appears"
echo "□ Paywall shows custom 'Omni_Final' design"
echo "□ Paywall cannot be swiped down to dismiss"
echo "□ After payment, navigates to sign-in"
echo "□ Users cannot get stuck on AI preview"

echo ""
echo -e "${GREEN}App is ready for manual testing${NC}"
echo "Please verify each step in the checklist above"