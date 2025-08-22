#!/bin/bash

# Auto-increment build number script for Xcode Build Phase
# Add this script to Build Phases in Xcode

echo "Build Configuration: $CONFIGURATION"
echo "Action: $ACTION"

# Get the current directory
cd "$PROJECT_DIR"

# Get current build number using agvtool
CURRENT_BUILD=$(agvtool what-version -terse)
echo "Current build number: $CURRENT_BUILD"

# Only increment for Archive builds (Release configuration)
if [ "$CONFIGURATION" == "Release" ]; then
    echo "Release configuration detected - incrementing build number..."
    
    # Increment the build number
    agvtool next-version -all
    
    # Get the new build number
    NEW_BUILD=$(agvtool what-version -terse)
    echo "Build number incremented to: $NEW_BUILD"
else
    echo "Not a Release build ($CONFIGURATION), keeping build number at $CURRENT_BUILD"
fi