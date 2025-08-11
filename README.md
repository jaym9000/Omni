# OmniAI - Mental Health Companion iOS App

A native iOS application built with SwiftUI, providing mental health support through an AI companion. This is a Swift/SwiftUI reimplementation of the original React Native OmniAI app.

## Features

- **AI Companion Chat**: Conversational AI support for mental health concerns
- **Mood Tracking**: Daily mood logging with emoji-based interface
- **Journal System**: Multiple journal types including free-form, tagged, and themed entries
- **Daily Prompts**: Gratitude and reflection prompts
- **Anxiety Relief Tools**: Breathing exercises, grounding techniques, and guided meditation
- **Premium Features**: Gated access to advanced features with subscription model
- **Dark Mode Support**: Automatic theme switching based on system preference
- **Secure Authentication**: Email/password and Apple Sign In support

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS Version**: iOS 16.0
- **Architecture**: MVVM with ObservableObject
- **State Management**: @StateObject, @EnvironmentObject, @AppStorage
- **Navigation**: NavigationStack with programmatic navigation

## Project Structure

```
Omni/
├── OmniAI.xcodeproj/        # Xcode project file
├── OmniAI/                  # Main app folder
│   ├── App/                 # App entry point
│   │   ├── OmniAIApp.swift
│   │   └── ContentView.swift
│   ├── Models/              # Data models
│   │   ├── User.swift
│   │   ├── ChatSession.swift
│   │   ├── MoodEntry.swift
│   │   └── JournalEntry.swift
│   ├── Views/               # UI components
│   │   ├── Authentication/  # Login, SignUp, etc.
│   │   ├── Home/           # Home screen and related views
│   │   ├── Chat/           # Chat interface
│   │   ├── Journal/        # Journal views
│   │   ├── Profile/        # Profile and settings
│   │   ├── Onboarding/     # Onboarding flow
│   │   └── Components/     # Reusable components
│   ├── Services/           # Business logic
│   │   ├── AuthenticationManager.swift
│   │   ├── ThemeManager.swift
│   │   └── PremiumManager.swift
│   ├── Assets.xcassets/   # Images and colors
│   └── Info.plist         # App configuration
└── README.md              # This file
```

## Setup Instructions

1. **Open in Xcode**
   ```bash
   cd /Users/jm/Desktop/Projects-2025/Omni
   open OmniAI.xcodeproj
   ```
   
   **Note**: Make sure to open `OmniAI.xcodeproj` (not any other .xcodeproj file)

2. **Configure Signing**
   - Select the OmniAI target
   - Go to "Signing & Capabilities"
   - Select your development team
   - Update the bundle identifier if needed

3. **Build and Run**
   - Select your target device/simulator
   - Press Cmd+R to build and run
   - The app should launch with the splash screen

## Key Components

### Authentication Flow
- Welcome screen with options for Sign Up / Sign In
- Email verification for new accounts
- Apple Sign In integration
- Password reset functionality

### Home Screen
- Mood tracking with 5 emotion options
- Chat with Omni button (premium feature)
- Daily gratitude prompt
- Anxiety relief toolkit card
- Recent chats access (premium)

### Journal System
- Free-form journaling
- Tagged entries for categorization
- Themed prompts for guided writing
- Daily reflection prompts

### Premium Features
- Unlimited chat conversations
- Mood-based chat suggestions
- Advanced analytics
- Export functionality
- Custom themes (future)
- Voice mode (future)

### Theme System
- Dynamic color system supporting light/dark modes
- Custom color palette with semantic naming
- Consistent typography scale
- Responsive spacing system

## Design Patterns

1. **MVVM Architecture**: Views observe ViewModels for state changes
2. **Environment Objects**: Shared state across the app hierarchy
3. **App Storage**: Persistent user preferences
4. **Protocol-Oriented Design**: Reusable components and behaviors
5. **Async/Await**: Modern concurrency for network operations

## UI/UX Features

- Smooth animations and transitions
- Haptic feedback for interactions
- Keyboard avoidance and management
- Pull-to-refresh where applicable
- Empty states with helpful guidance
- Loading states and progress indicators
- Error handling with user-friendly messages

## Security & Privacy

- Face ID/Touch ID support (biometric authentication)
- Secure data storage using Keychain
- Email verification for new accounts
- Privacy-focused design

## Future Enhancements

- Voice conversation mode
- Advanced mood analytics charts
- Social features (anonymous community)
- Integration with HealthKit
- Widget support for mood tracking
- Push notifications for reminders
- CloudKit sync for data backup

## Build Requirements

- Xcode 15.0 or later
- macOS Ventura 13.0 or later
- iOS 16.0+ deployment target
- Swift 5.9+

## Testing

The app includes:
- Preview providers for SwiftUI views
- Mock data for development
- Simulated API responses for demo mode

## Notes

This is a UI/UX focused implementation without backend integration. All data is currently mocked or stored locally. To connect to a real backend:

1. Replace mock API calls in manager classes
2. Implement proper networking layer
3. Add authentication token management
4. Configure API endpoints
5. Handle real-time updates if needed

## License

This project is a reimplementation for demonstration purposes. Original concept from OmniAI React Native app.