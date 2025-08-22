#!/bin/bash

# Auto-increment build number for Archives only
# Uses agvtool for proper Xcode integration

# Get the directory containing the xcodeproj
cd "$SRCROOT"

# Only increment for Archive builds
if [ "$ACTION" == "install" ] || [ "$CONFIGURATION" == "Release" ]; then
    
    echo "Auto-incrementing build number for Archive..."
    
    # Get current build number
    CURRENT_BUILD=$(agvtool what-version -terse)
    echo "Current build number: $CURRENT_BUILD"
    
    # Increment build number
    agvtool next-version -all
    
    # Get new build number
    NEW_BUILD=$(agvtool what-version -terse)
    echo "New build number: $NEW_BUILD"
    
    # Optional: Update marketing version if needed
    # agvtool new-marketing-version 1.1
    
else
    echo "Not an Archive build, skipping build number increment"
fi