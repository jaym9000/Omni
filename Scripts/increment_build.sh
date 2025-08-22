#!/bin/bash

# Simple build number auto-increment script
# Add this as a Build Phase in Xcode

# Only run for Archive builds
if [ "$ACTION" == "install" ]; then
    echo "Incrementing build number for Archive..."
    
    # Get the Info.plist file path
    INFO_PLIST="${PROJECT_DIR}/${INFOPLIST_FILE}"
    
    # Get current build number
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST")
    echo "Current build number: $buildNumber"
    
    # Increment build number
    buildNumber=$((buildNumber + 1))
    
    # Set new build number
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$INFO_PLIST"
    echo "Build number incremented to: $buildNumber"
    
    # Optional: Commit the change to git
    # git add "$INFO_PLIST"
    # git commit -m "Auto-increment build number to $buildNumber"
else
    echo "Not an archive build, skipping increment"
fi