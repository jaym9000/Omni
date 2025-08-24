#!/bin/bash

echo "🔧 Setting up proper code signing for OmniAI"
echo "==========================================="

# Step 1: Install the provisioning profile properly
echo "Step 1: Installing provisioning profile..."
PROFILE_PATH="/Users/jm/Desktop/Projects-2025/Omni/Temp/[expo]_comjnsOmni_AppStore_20250615T231750037Z.mobileprovision"
if [ -f "$PROFILE_PATH" ]; then
    UUID=$(security cms -D -i "$PROFILE_PATH" | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
    cp "$PROFILE_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/$UUID.mobileprovision
    echo "✅ Profile installed with UUID: $UUID"
else
    echo "❌ Profile not found at $PROFILE_PATH"
fi

# Step 2: Clear Xcode caches
echo ""
echo "Step 2: Clearing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/OmniAI-*
killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null

# Step 3: Build with manual signing
echo ""
echo "Step 3: Building with manual signing..."
xcodebuild -project /Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj \
    -scheme OmniAI \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -configuration Debug \
    clean build \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=92493ZAN98 \
    PROVISIONING_PROFILE_SPECIFIER="[expo] com.jns.Omni AppStore 2025-06-15T23:17:50.037Z" \
    CODE_SIGN_IDENTITY="iPhone Distribution" 2>&1 | tail -20

echo ""
echo "✅ Setup complete!"
echo ""
echo "In Xcode, you should now see:"
echo "1. Manual signing selected"
echo "2. The correct provisioning profile"
echo "3. In-App Purchase capability enabled"
echo ""
echo "If you still see errors in Xcode:"
echo "1. Click on the project navigator (blue icon)"
echo "2. Select the OmniAI target"
echo "3. Go to Signing & Capabilities"
echo "4. Click 'Try Again' if there's an error"