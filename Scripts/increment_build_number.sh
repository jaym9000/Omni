#!/bin/bash

# Auto-increment build number script for Xcode
# This script automatically increments the build number each time you archive

# Only increment for Release builds (Archive)
if [ "$CONFIGURATION" == "Release" ]; then
    
    # Get the current build number
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}")
    
    # Increment the build number
    buildNumber=$((buildNumber + 1))
    
    # Update the build number in Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
    
    # Also update in the source Info.plist to persist the change
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${SRCROOT}/${INFOPLIST_FILE}"
    
    echo "Build number incremented to: $buildNumber"
    
else
    echo "Skipping build increment for configuration: $CONFIGURATION"
fi