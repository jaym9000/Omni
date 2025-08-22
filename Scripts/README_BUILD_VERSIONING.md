# Build Versioning Setup for TestFlight

## Current Version Info
- **Marketing Version**: 1.1
- **Build Number**: 23

## Auto-Increment Setup Instructions

### Method 1: Xcode Build Phase (Recommended)

1. Open `OmniAI.xcodeproj` in Xcode
2. Select the OmniAI target
3. Go to **Build Phases** tab
4. Click the **+** button and select **New Run Script Phase**
5. Name it "Auto-Increment Build Number"
6. Drag it to run **AFTER** "Copy Bundle Resources" but **BEFORE** "Upload Debug Symbols"
7. Add this script:

```bash
# Only increment for Archive builds
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
else
    echo "Not an archive build, skipping increment"
fi
```

8. Make sure **"Based on dependency analysis"** is UNCHECKED

### Method 2: Using agvtool (Alternative)

From Terminal, in the project directory:

```bash
# Increment build number manually
agvtool next-version -all

# Set a specific build number
agvtool new-version -all 24

# Check current build number
agvtool what-version -terse
```

## Archiving for TestFlight

1. In Xcode, select **Generic iOS Device** or your connected device as the build destination
2. Clean the build folder: **Product > Clean Build Folder** (⇧⌘K)
3. Archive the app: **Product > Archive**
4. The build number will automatically increment to 24
5. Once archived, the Organizer will open
6. Select your archive and click **Distribute App**
7. Choose **App Store Connect**
8. Choose **Upload**
9. Follow the prompts to upload to TestFlight

## Manual Version Management

If you need to change versions manually:

```bash
# Update marketing version (e.g., for a new release)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.2" OmniAI/Info.plist

# Update build number
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 30" OmniAI/Info.plist
```

## Important Notes

- Build numbers must be unique for each upload to TestFlight
- Build numbers must increase for the same marketing version
- The auto-increment only runs when archiving (not for regular builds)
- Always commit your Info.plist changes after a successful TestFlight upload

## Troubleshooting

If the build number doesn't increment:
1. Check that the script has execute permissions
2. Ensure the Info.plist path is correct in Build Settings
3. Verify you're actually archiving (not just building)
4. Check Xcode's build logs for script output