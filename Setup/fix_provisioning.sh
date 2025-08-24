#!/bin/bash

echo "🔧 Fixing In-App Purchase Provisioning Profile Issue"
echo "=================================================="

# Step 1: Clean everything
echo ""
echo "Step 1: Cleaning build artifacts..."
cd /Users/jm/Desktop/Projects-2025/Omni
xcodebuild clean -project OmniAI.xcodeproj -scheme OmniAI -quiet

# Step 2: Remove derived data more aggressively
echo "Step 2: Removing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/OmniAI-*

# Step 3: Show current bundle ID
echo ""
echo "Step 3: Current Bundle ID:"
grep PRODUCT_BUNDLE_IDENTIFIER OmniAI.xcodeproj/project.pbxproj | head -1

# Step 4: Instructions for manual steps
echo ""
echo "📱 MANUAL STEPS REQUIRED IN XCODE:"
echo "=================================="
echo ""
echo "1. In Xcode (already open):"
echo "   a. Click on 'OmniAI' project in navigator"
echo "   b. Select 'OmniAI' target"
echo "   c. Go to 'Signing & Capabilities' tab"
echo ""
echo "2. Toggle Automatic Signing:"
echo "   a. UNCHECK 'Automatically manage signing'"
echo "   b. When prompted, click 'Enable Manual Signing'"
echo "   c. WAIT 2 seconds"
echo "   d. CHECK 'Automatically manage signing' again"
echo "   e. Select your team from dropdown"
echo ""
echo "3. Click 'Try Again' button if it appears"
echo ""
echo "4. Alternative - Add capability manually:"
echo "   a. Click '+' button in Signing & Capabilities"
echo "   b. Search for 'In-App Purchase'"
echo "   c. Double-click to add it (if not already there)"
echo ""
echo "📱 WHAT XCODE IS DOING:"
echo "======================="
echo "- Communicating with Apple Developer Portal"
echo "- Updating your App ID (com.jns.Omni) to include IAP"
echo "- Generating new provisioning profile"
echo "- Downloading and installing the profile"
echo ""
echo "⏳ This may take 30-60 seconds..."
echo ""
echo "🔍 TO VERIFY IT WORKED:"
echo "======================="
echo "- The red error should disappear"
echo "- Build should succeed"
echo "- You should see a checkmark next to 'In-App Purchase'"
echo ""
echo "Press any key after completing the manual steps..."
read -n 1 -s

# Step 5: Try to build to verify
echo ""
echo "Step 5: Attempting build to verify fix..."
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build -quiet 2>&1 | grep -E "(SUCCEEDED|FAILED|error:)" | tail -5

echo ""
echo "✅ Script complete! Check if the build succeeded above."
echo ""
echo "If still having issues:"
echo "1. Go to https://developer.apple.com"
echo "2. Navigate to Certificates, Identifiers & Profiles → Identifiers"
echo "3. Find 'com.jns.Omni' and edit it"
echo "4. Ensure 'In-App Purchase' is checked and save"
echo "5. Return to Xcode and try again"