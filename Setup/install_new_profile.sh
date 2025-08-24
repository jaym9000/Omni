#!/bin/bash

echo "📱 Installing Updated Provisioning Profile"
echo "=========================================="
echo ""
echo "After downloading the regenerated profile from Apple Developer Portal:"
echo ""
echo "1. Move the downloaded .mobileprovision file to:"
echo "   /Users/jm/Desktop/Projects-2025/Omni/Temp/"
echo ""
echo "2. Run this command with the new filename:"
echo ""
echo "   ./install_new_profile.sh [filename.mobileprovision]"
echo ""

if [ "$1" ]; then
    PROFILE_PATH="/Users/jm/Desktop/Projects-2025/Omni/Temp/$1"
    
    if [ -f "$PROFILE_PATH" ]; then
        # Extract UUID and install
        UUID=$(security cms -D -i "$PROFILE_PATH" | plutil -extract UUID xml1 -o - - | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
        
        # Install to Xcode
        cp "$PROFILE_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/$UUID.mobileprovision
        
        # Open the profile to install in Xcode
        open "$PROFILE_PATH"
        
        echo "✅ Profile installed with UUID: $UUID"
        echo ""
        echo "Now in Xcode:"
        echo "1. The profile should automatically update"
        echo "2. The '1 Missing' error should disappear"
        echo "3. Build should succeed"
    else
        echo "❌ File not found: $PROFILE_PATH"
    fi
else
    echo "Usage: ./install_new_profile.sh [filename.mobileprovision]"
fi