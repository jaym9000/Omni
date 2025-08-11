# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OmniAI is a therapeutic mental health companion iOS app built with SwiftUI. Originally a React Native app, this is a complete Swift/SwiftUI reimplementation focusing on evidence-based design for anxiety and depression support.

**Current Version:** 1.1 (22)
**Key Technical Details:**
- Swift 5.9+ with SwiftUI framework  
- iOS 16.0+ deployment target
- Architecture: MVVM with ObservableObject pattern
- No backend integration - all data is mocked/local

## Development Commands

### Building and Running
```bash
# Open correct project (critical - there may be old project files)
open OmniAI.xcodeproj

# Build via command line
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI -destination 'platform=iOS Simulator,name=iPhone 16' build

# Archive for TestFlight (version/build auto-incremented in project.pbxproj)
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI -configuration Release archive
```

**Critical:** Always use `OmniAI.xcodeproj` - ignore any old `Omni.xcodeproj` files.

### Version Management
Version info is stored in `project.pbxproj`:
- `MARKETING_VERSION` = user-facing version (e.g. "1.1") 
- `CURRENT_PROJECT_VERSION` = build number (e.g. "22")
- Profile screen dynamically shows these via `Bundle.main.object(forInfoDictionaryKey:)`

### No Testing Framework
App uses SwiftUI Preview providers only. All data is mocked - no real API integration.

## Architecture Overview

### Core State Management Pattern
The app uses a three-manager system injected as environment objects:
- **AuthenticationManager**: User authentication, sign-in/sign-up flow
- **PremiumManager**: Subscription features and premium access control  
- **ThemeManager**: Dark/light mode and color system

These are injected at the app root in `OmniAIApp.swift` and accessed throughout the view hierarchy via `@EnvironmentObject`.

### Navigation & State Flow
**Key Pattern:** The app avoids NavigationStack in favor of programmatic sheet/fullScreenCover presentations for major flows:
- Chat is presented via `fullScreenCover` 
- Mood selection uses callback pattern from child to parent
- Bottom sheets use `presentationDetents` for partial coverage

**Mood Flow Architecture:** When a user selects a mood emoji:
1. `HomeView` shows `MoodBottomSheet` via `.sheet()`
2. MoodBottomSheet uses callback pattern: `onTalkToOmni: (String) -> Void` 
3. Parent `HomeView` manages chat presentation state and initial prompt
4. This prevents modal-within-modal dismissal issues

### Data Models
- **MoodEntry**: Enum-based mood tracking with emoji, color, and labels
- **ChatMessage**: Simple message model with content, user flag, timestamp
- **JournalEntry**: Support for free-form, tagged, and themed journal entries
- **User**: Authentication model supporting email and Apple Sign In

### UI Component Patterns
- **Callback-driven components**: Complex components like `MoodBottomSheet` use callback parameters rather than internal navigation
- **Environment color system**: Custom semantic colors (`.omniTextPrimary`, `.omniprimary`, etc.)
- **State hoisting**: Child components receive state and callbacks from parents rather than managing their own navigation

## Therapeutic Design System (Evidence-Based)

### Color Psychology Implementation
**Critical:** This app uses scientifically-researched therapeutic colors to reduce anxiety:
- **Primary Color:** Sage green (`#7FB069`) - proven to reduce anxiety and heart rate
- **Backgrounds:** Warm cream (`#F9F7F4`) instead of clinical white - creates nurturing environment  
- **Text Colors:** Warm grays (`#3A3D42`, `#6B7280`) - less harsh than pure black
- **Mood Colors:** Muted versions (avoid bright yellow/orange that trigger anxious users)

**Key Research:** Users with anxiety/depression avoid warm colors and prefer soft blues/greens. All colors defined in `ThemeManager.swift` extension.

### Therapeutic UX Patterns
- **Gentle Mood Emojis:** `🙂😔🙁😮‍💨😌` (avoid intense expressions like `😰🤯😢`)
- **Soft Interactions:** Only specific buttons clickable (not entire cards) 
- **Calming Animations:** Smooth, slow transitions to reduce stimulation
- **Therapeutic Messaging:** "Your safe space for mental wellness" branding

### Mental Health Features Implementation

#### Mood-Aware Chat System
Chat behavior adapts to emotional context:
- Mood-triggered chats receive empathetic initial prompts: "I see you're feeling [mood]..."
- Chat/Voice toggle with polished circular mic button (not boxy design)
- Generic welcome for non-mood chats: "Hi there! 👋 How are you feeling today?"

#### Anxiety Management Card
Special interaction pattern:
- **Only "Let's Start" button is clickable** (not entire card surface)
- Uses stress-reducing lavender background (`omniCardLavender`)
- Compact design with leaf icon and therapeutic sage green button

#### Journal System with Therapeutic Colors
- **Free-form:** Beige cards (`omniCardBeige`) for warmth
- **Tagged/Themed:** Lavender cards (`omniCardLavender`) for calm
- Empty states properly centered for all device sizes
- Soft placeholder text and gentle encouragement

## Development Notes

### Premium Feature Gates
Premium features are controlled via `PremiumManager.isPremium`. Components check this before allowing access to:
- Unlimited chat conversations
- Chat history access
- Advanced mood analytics
- Export functionality

### Data Persistence
Currently uses local storage only:
- `@AppStorage` for user preferences and daily data
- `UserDefaults` for authentication state
- No backend integration (all API calls are mocked)

### Animation & UX Patterns
- Bottom sheets use `.presentationDetents([.height(300), .medium])`
- State changes use `.animation()` modifiers for smooth transitions
- Callback pattern prevents navigation stack complexity

### Asset Management
Images use proper Xcode imageset structure in `Assets.xcassets/Images/`. Each image requires a `Contents.json` file with scale variants.

### Therapeutic Color System
All colors in `ThemeManager.swift` are research-based for mental health:
- **Text Hierarchy:** `.omniTextPrimary` (warm dark gray), `.omniTextSecondary` (medium), `.omniTextTertiary` (light)
- **Therapeutic Cards:** `.omniCardBeige`, `.omniCardLavender`, `.omniCardSoftBlue`
- **Mood Colors:** Muted versions - `.moodHappy` (soft yellow), `.moodAnxious` (coral), `.moodCalm` (sage)
- **Brand Color:** `.omniprimary` (therapeutic sage green #7FB069)

## Critical Design Patterns When Making Changes

### 1. Therapeutic Color Consistency
**Always maintain the evidence-based color system:**
```swift
// ✅ Good - uses therapeutic colors
.background(Color.omniCardLavender)
.foregroundColor(.omniprimary)

// ❌ Bad - breaks therapeutic design
.background(Color.white)  
.foregroundColor(.blue)
```

### 2. Gentle User Interactions  
**Only make intended elements clickable:**
```swift
// ✅ Good - specific button only
VStack {
    Text("Content")  // Not clickable
    Button("Action") { ... }  // Only this clickable
}

// ❌ Bad - entire card clickable
Button(action: { ... }) {
    VStack { /* entire content */ }
}
```

### 3. Mental Health-Appropriate UX
- Use gentle, non-alarming language
- Implement smooth, calming animations  
- Avoid bright/stimulating colors (yellow, orange, bright red)
- Center empty states properly with GeometryReader for all devices
- Use muted emoji expressions to avoid triggering sensitive users

### 4. App-Specific Navigation Patterns
- **Chat:** Use `fullScreenCover` with dismiss pattern
- **Mood Selection:** Callback pattern to parent, avoid nested modals
- **Bottom Sheets:** `.presentationDetents([.height(300), .medium])`
- **State Flow:** Inject environment objects, use callback pattern for complex interactions

### 5. Version Updates
Update both version fields in `project.pbxproj`:
- `MARKETING_VERSION` for user-facing version
- `CURRENT_PROJECT_VERSION` for build number (must always increment)

## Simulator Testing
iPhone-only app - use iPhone simulators. iPad layouts not supported/optimized.