# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OmniAI is a native iOS mental health companion app built with SwiftUI. It's a complete reimplementation of a React Native app, focusing on mood tracking, AI chat support, journaling, and anxiety management tools.

**Key Details:**
- Swift 5.9+ with SwiftUI framework
- iOS 16.0+ deployment target
- Bundle ID: `com.omniai.mentalhealth`
- Architecture: MVVM with ObservableObject pattern

## Development Commands

### Building and Running
```bash
# Build for iPhone 16 simulator (recommended)
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build

# Install to simulator
xcrun simctl install booted /path/to/OmniAI.app

# Launch app
xcrun simctl launch booted com.omniai.mentalhealth
```

**Important:** Always use `OmniAI.xcodeproj` (not any old Omni.xcodeproj files that may exist).

### Testing
The app uses SwiftUI Preview providers for UI testing. No formal unit tests are currently implemented. All functionality is mocked for development.

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

## Mental Health Features Implementation

### Mood-Aware Chat System
The chat system has special behavior for mood-based conversations:
- When launched from mood selection, AI's first message acknowledges the selected emotion
- Different initial prompts per mood: "I see you're feeling [mood] today..."
- Regular chat (non-mood) shows generic welcome message

### Anxiety Management Toolkit  
`AnxietySessionView` provides 6 different techniques:
- Box Breathing, 5-4-3-2-1 Grounding, Body Scan, Positive Affirmations, Anxiety Journal, Quick Calm
- Each technique has dedicated UI with step-by-step instructions
- Uses programmatic sheet presentation for technique details

### Journal System
Three types of journaling supported:
- Free-form text entry
- Tagged entries with mood/topic categorization  
- Themed prompts for guided writing

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

### Color System
Custom semantic color names throughout:
- `.omniTextPrimary`, `.omniTextSecondary` for text hierarchy
- `.omniprimary` for brand color
- `.moodHappy`, `.moodAnxious`, etc. for mood-specific colors

## Common Patterns When Making Changes

1. **Adding new views**: Inject needed environment objects and use callback pattern for navigation
2. **State management**: Prefer `@StateObject` in parent, `@ObservedObject` in children
3. **Modal presentations**: Use `fullScreenCover` for major flows, `sheet` with `presentationDetents` for bottom sheets
4. **Chat modifications**: Remember that chat initial prompts come from mood selection callbacks
5. **Premium features**: Always check `PremiumManager.isPremium` before enabling functionality

## Testing in Simulator
The app is configured for iPhone-sized devices. iPad layouts are not optimized. Use iPhone simulators for development and testing.