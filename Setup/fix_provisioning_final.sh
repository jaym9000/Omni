#!/bin/bash

echo "🔧 Final Provisioning Profile Fix"
echo "=================================="
echo ""

# Step 1: Clear Xcode derived data completely
echo "Step 1: Clearing all Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Step 2: Reset provisioning profiles
echo "Step 2: Resetting provisioning profiles..."
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/ 2>/dev/null
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/

# Step 3: Open Xcode to the right location
echo ""
echo "Step 3: Opening Xcode..."
open /Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj

echo ""
echo "📱 CRITICAL STEPS IN XCODE:"
echo "============================"
echo ""
echo "1. Wait for Xcode to fully load"
echo ""
echo "2. Click on the OmniAI project (blue icon) in navigator"
echo ""
echo "3. Select the OmniAI target"
echo ""
echo "4. Go to 'Signing & Capabilities' tab"
echo ""
echo "5. You should see an error about provisioning profile"
echo ""
echo "6. Click the '🔄 Try Again' button next to the error"
echo "   (This forces Xcode to regenerate with IAP capability)"
echo ""
echo "7. If no 'Try Again' button:"
echo "   a. Change Team to 'None'"
echo "   b. Change back to 'Jean-Marc Rugomboka-Mahoro (Personal Team)'"
echo "   c. Click 'Try Again' when it appears"
echo ""
echo "8. The error should resolve within 10-30 seconds"
echo ""
echo "⚠️  IMPORTANT: If still failing:"
echo "================================"
echo "1. In Apple Developer Portal (already opened):"
echo "   - Find 'com.jns.Omni' identifier"
echo "   - Click on it to edit"
echo "   - Ensure 'In-App Purchase' is checked"
echo "   - Click 'Save'"
echo ""
echo "2. Back in Xcode:"
echo "   - Click 'Try Again' button"
echo ""

# Step 4: Try to trigger Xcode to refresh
echo "Step 4: Triggering Xcode refresh..."
xcodebuild -project /Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj -list >/dev/null 2>&1

echo ""
echo "✅ Script complete! Follow the manual steps above in Xcode."