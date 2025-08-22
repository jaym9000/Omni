# Archive and TestFlight Instructions

## Current Version Status
- **Marketing Version**: 1.1
- **Build Number**: 23 (ready for next archive)

## Auto-Increment Setup (One-Time)

### Option 1: Build Phase Script (Recommended)
1. Open `OmniAI.xcodeproj` in Xcode
2. Select the **OmniAI** target (not the project)
3. Go to **Build Phases** tab
4. Click **+** → **New Run Script Phase**
5. Name it: "Auto-Increment Build Number"
6. **IMPORTANT**: Drag it to be FIRST (before "Dependencies")
7. Paste this script:

```bash
cd "$PROJECT_DIR"
if [ "$CONFIGURATION" == "Release" ]; then
    agvtool next-version -all
    echo "Build incremented to $(agvtool what-version -terse)"
fi
```

8. **UNCHECK** "Based on dependency analysis"
9. **CHECK** "Run script: For install builds only"

### Option 2: Archive Pre-Action
1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Archive** on the left
3. Click **Pre-actions** → **+** → **New Run Script Action**
4. Set **Provide build settings from**: OmniAI
5. Add script:
```bash
cd "$SRCROOT"
agvtool next-version -all
```

## Manual Build Increment (Before Archive)
If auto-increment isn't working, manually increment:

```bash
cd /Users/jm/Desktop/Projects-2025/Omni
agvtool next-version -all
```

## Archive Process

1. **Clean First**:
   - Product → Clean Build Folder (⇧⌘K)

2. **Select Device**:
   - Choose "Any iOS Device (arm64)" from device selector

3. **Archive**:
   - Product → Archive
   - Wait for build to complete

4. **Verify Build Number**:
   - In Organizer, check the build number (should be 24 or higher)

5. **Upload to TestFlight**:
   - Click **Distribute App**
   - Select **App Store Connect**
   - Select **Upload**
   - Choose **Automatically manage signing**
   - Click **Upload**

## Troubleshooting

### Build number didn't increment?
```bash
# Check current version
agvtool what-version -terse

# Manually set to next number
agvtool new-version -all 24

# Verify it's updated
cat OmniAI/Info.plist | grep -A1 CFBundleVersion
```

### Archive fails?
1. Check provisioning profiles in Xcode
2. Ensure you're signed into App Store Connect
3. Verify bundle ID matches: `com.jns.Omni`

### TestFlight upload fails?
- Build numbers must be unique
- Must be higher than previous uploads
- Check App Store Connect for any validation errors

## Quick Commands

```bash
# Check current build
agvtool what-version -terse

# Increment build
agvtool next-version -all

# Set specific build
agvtool new-version -all 25

# Check marketing version
agvtool what-marketing-version -terse1

# Update marketing version (for new releases)
agvtool new-marketing-version 1.2
```

## Next Steps
Your next archive will be build 24 (or higher if you've already incremented).
After successful TestFlight upload, the build will be available for testing in ~5-10 minutes.