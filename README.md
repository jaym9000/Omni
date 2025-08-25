# OmniAI - Mental Health Companion iOS App

A production-ready iOS mental health companion app featuring AI-powered therapeutic support, built with SwiftUI and Firebase backend integration.

## 🚀 Production Features

### Core Functionality
- **AI Therapy Chat**: Unlimited GPT-4 powered conversations via Firebase Cloud Functions
- **Mood Tracking**: Daily mood logging with analytics and insights
- **Journal System**: Free-form, tagged, and themed journal entries
- **Daily Prompts**: Gratitude exercises and reflection prompts
- **Anxiety Management**: Breathing exercises and grounding techniques
- **Paid-Only Model**: Premium subscription required (NO FREE TIER)
- **Premium Subscriptions**: RevenueCat integration with App Store subscriptions
- **No Rate Limits**: Unlimited messages for all paid users

### Technical Features
- **Real-time Sync**: Firebase Firestore for instant data updates
- **Secure Authentication**: Firebase Auth with email/password and Apple Sign-In
- **Client-Side Encryption**: AES-256 encryption for sensitive data via CryptoKit
- **Analytics Integration**: Firebase Analytics with conversion funnel tracking
- **Offline Support**: Message queuing and offline data persistence
- **Dark Mode**: Automatic theme switching based on system preference
- **Biometric Security**: Face ID/Touch ID support

## 💻 Tech Stack

### Frontend
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with ObservableObject
- **State Management**: @StateObject, @EnvironmentObject, @AppStorage
- **Minimum iOS**: 16.0+

### Backend Services
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Cloud Functions**: Node.js with TypeScript
- **AI Integration**: OpenAI GPT-4 API
- **Subscriptions**: RevenueCat SDK
- **Analytics**: Firebase Analytics

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
│   │   ├── ChatService.swift
│   │   ├── FirebaseManager.swift
│   │   ├── JournalManager.swift
│   │   ├── PremiumManager.swift
│   │   ├── RevenueCatManager.swift
│   │   ├── AnalyticsManager.swift
│   │   ├── EncryptionManager.swift
│   │   └── ThemeManager.swift
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

**Apple OAuth JWT Maintenance**: The Apple OAuth client secret (JWT) expires every 6 months. Next renewal required: **February 17, 2026**. Use the `generate_apple_secret.js` script to regenerate the JWT and update it in your Firebase console.

### Home Screen
- Mood tracking with 5 emotion options
- Chat with Omni button (requires subscription)
- Daily gratitude prompt
- Anxiety relief toolkit card
- Recent chats access

### Journal System
- Free-form journaling
- Tagged entries for categorization
- Themed prompts for guided writing
- Daily reflection prompts

### Premium Features (Required for App Access)
- Unlimited AI chat conversations
- Mood-based chat suggestions
- Advanced mood analytics
- Journal entries
- Export functionality (planned)
- Voice mode (UI exists, backend planned)
- Custom themes (planned)

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

## 🔐 Security & Privacy

### Core Security Features
- **Client-side encryption** using AES-256 via CryptoKit
- **Secure authentication** with Firebase Auth and biometric support
- **Token management** with Keychain Services
- **Rate limiting** on Firebase Cloud Functions (60 req/min per user)
- **Crisis detection** with support resource links
- **Privacy-first design** with minimal data collection
- **Audit logging** for administrative access

### Advanced Security Implementations
- **Firebase App Check** for API protection
- **Certificate pinning** to prevent MITM attacks
- **Jailbreak detection** for compromised devices
- **Input validation** and content moderation
- **Security monitoring** with real-time alerts
- **OWASP Mobile Top 10** full compliance
- **End-to-end encryption** for sensitive messages

## 📈 Business Model

### Hard Paywall Subscription Model
- **Subscription Required**: App requires active subscription after onboarding
- **Pricing Tiers**:
  - Weekly: Price configured in RevenueCat
  - Monthly: Price configured in RevenueCat
  - Yearly: Price configured in RevenueCat

### Trial System
- 7-day free trial for all subscription tiers
- Simplified onboarding with AI preview
- Immediate paywall presentation via RevenueCat
- Auto-renewal after trial period

## 🚀 Deployment Status

- **App Store**: Version 1.1 (Build 29) production ready
- **Bundle ID**: com.jns.Omni
- **Firebase Project**: omni-ai-8d5d2 (us-central1)
- **Cloud Functions**: Deployed and active (aiChat function with security layers)
- **RevenueCat**: "Omni New" offering configured with "Omni_Final" paywall
- **Security**: Full OWASP Mobile Top 10 compliance implemented

## 📱 Installation

### For Users
Download from the App Store (pending approval) or join TestFlight beta.

### For Developers
1. Clone the repository
2. Open `OmniAI.xcodeproj` in Xcode 15+
3. Add `GoogleService-Info.plist` to the project
4. Configure RevenueCat API keys
5. Build and run on iOS 16.0+ device/simulator

## 🧪 Testing

Run test scripts from the Testing directory:
```bash
# Monetization and subscription tests
./Testing/test_monetization_flows.sh
./Testing/verify_monetization_config.sh

# End-to-end functionality tests
./Testing/test_end_to_end.sh

# Security testing suite
./Scripts/security_test_suite.sh
./Scripts/test_security_implementation.sh
./Scripts/verify_security_integration.sh
```

## 📄 License

Proprietary - © 2024 Jon McCormick. All rights reserved.