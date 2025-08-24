#!/bin/bash

echo "📱 Installing OmniAI IAP Production Provisioning Profile"
echo "========================================================"
echo ""

# Look for the new profile in Downloads
PROFILE_PATH=$(ls -t ~/Downloads/*IAP*.mobileprovision 2>/dev/null | head -1)

if [ -z "$PROFILE_PATH" ]; then
    echo "❌ No IAP provisioning profile found in Downloads"
    echo ""
    echo "Please:"
    echo "1. Go to Apple Developer Portal"
    echo "2. Create profile named 'OmniAI IAP Production 2025'"
    echo "3. Download it to your Downloads folder"
    echo "4. Run this script again"
    exit 1
fi

echo "Found profile: $(basename "$PROFILE_PATH")"
echo ""

# Extract UUID
UUID=$(security cms -D -i "$PROFILE_PATH" 2>/dev/null | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')

# Check if profile has IAP entitlement
HAS_IAP=$(security cms -D -i "$PROFILE_PATH" 2>/dev/null | grep -c "com.apple.developer.in-app-purchase")

if [ "$HAS_IAP" -eq 0 ]; then
    echo "⚠️  WARNING: This profile does NOT contain In-App Purchase entitlement!"
    echo ""
    echo "You need to:"
    echo "1. Go to developer.apple.com/account/resources/identifiers/list"
    echo "2. Click on 'XC com jns Omni'"
    echo "3. Enable 'In-App Purchase' capability"
    echo "4. Save the changes"
    echo "5. Create a NEW provisioning profile"
    echo ""
else
    echo "✅ Profile contains In-App Purchase entitlement!"
fi

# Install profile
echo "Installing profile with UUID: $UUID"
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/
cp "$PROFILE_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/$UUID.mobileprovision

# Open profile to register with Xcode
open "$PROFILE_PATH"

echo ""
echo "✅ Profile installed!"
echo ""
echo "Next steps in Xcode:"
echo "1. Close and reopen your project"
echo "2. Go to Signing & Capabilities"
echo "3. Select 'OmniAI IAP Production 2025' from Provisioning Profile dropdown"
echo "4. Build your project"
echo ""

# Restart Xcode
osascript -e 'tell application "Xcode" to quit' 2>/dev/null
sleep 2
open /Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj

echo "🚀 Xcode is restarting with the new profile..."