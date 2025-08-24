# OmniAI Technical Architecture Documentation
*Last Updated: January 24, 2025*

## 🏗️ System Architecture Overview

OmniAI is a production-ready iOS mental health companion app built with a modern, scalable architecture using SwiftUI, Firebase backend services, and a hard paywall subscription model via RevenueCat.

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS Client                           │
│                     (SwiftUI + MVVM)                        │
├─────────────────────────────────────────────────────────────┤
│                      Service Layer                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Auth    │ │  Chat    │ │ Revenue  │ │Analytics │      │
│  │ Manager  │ │ Service  │ │   Cat    │ │ Manager  │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
├─────────────────────────────────────────────────────────────┤
│                     Security Layer                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │  Encryption  │ │   Keychain   │ │ Biometric    │       │
│  │   Manager    │ │   Storage    │ │    Auth      │       │
│  └──────────────┘ └──────────────┘ └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Firebase Backend                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │   Auth   │ │Firestore │ │   Cloud  │ │Analytics │      │
│  │          │ │    DB    │ │Functions │ │          │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                   │
│  │ OpenAI   │ │RevenueCat│ │  Apple   │                   │
│  │  GPT-4   │ │   IAP    │ │ Sign-In  │                   │
│  └──────────┘ └──────────┘ └──────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## 📱 iOS Application Architecture

### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM with ObservableObject
- **Minimum iOS Version**: 16.0
- **Bundle ID**: com.jns.Omni

### Application Structure

```
OmniAI/
├── App/
│   ├── OmniAIApp.swift          # App entry point, environment setup
│   └── ContentView.swift        # Main navigation container
├── Models/
│   ├── User.swift               # User data model
│   ├── ChatSession.swift        # Chat session model
│   ├── ChatMessage.swift        # Message model with encryption
│   ├── MoodEntry.swift          # Mood tracking model
│   └── JournalEntry.swift       # Journal entry model
├── Views/
│   ├── Authentication/
│   │   ├── WelcomeView.swift
│   │   ├── SignInView.swift
│   │   ├── SignUpView.swift
│   │   ├── EmailVerificationView.swift
│   │   └── PostTrialSignInView.swift
│   ├── Onboarding/
│   │   ├── SimpleWelcomeView.swift
│   │   ├── QuickSetupView.swift
│   │   ├── AIPreviewView.swift
│   │   └── OnboardingView.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   └── ChatDetailView.swift
│   ├── Journal/
│   │   └── JournalView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── SubscriptionManagementView.swift
│   │   ├── DataExportView.swift
│   │   └── PrivacyPolicyView.swift
│   └── Components/
│       ├── MoodBottomSheet.swift
│       └── PaywallView.swift
└── Services/
    ├── AuthenticationManager.swift
    ├── ChatService.swift
    ├── FirebaseManager.swift
    ├── JournalManager.swift
    ├── PremiumManager.swift
    ├── RevenueCatManager.swift
    ├── AnalyticsManager.swift
    ├── EncryptionManager.swift
    └── ThemeManager.swift
```

## 🔐 Authentication & Security

### Authentication Flow
1. **Email/Password Authentication**
   - Firebase Auth with email verification
   - Password reset functionality
   - Secure token management

2. **Apple Sign-In**
   - Native OAuth implementation via Firebase
   - Automatic account linking
   - JWT token handling

3. **Biometric Authentication**
   - Face ID/Touch ID integration
   - Keychain-backed secure storage
   - Fallback to passcode

### Security Implementation

#### Client-Side Encryption
```swift
// EncryptionManager.swift
- Algorithm: AES-256-GCM
- Key Storage: iOS Keychain
- Scope: Sensitive messages and journal entries
- Implementation: CryptoKit framework
```

#### Data Protection Levels
- **User Credentials**: Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
- **Session Tokens**: In-memory with automatic refresh
- **Cached Data**: Encrypted Core Data with NSFileProtectionComplete
- **Analytics**: Anonymized and aggregated

## 🔥 Firebase Backend Architecture

### Project Configuration
```yaml
Project ID: omni-ai-8d5d2
Region: us-central1
Environment: Production
```

### Firestore Database Schema

#### Collections Structure
```javascript
// users/{userId}
{
  uid: string,
  email: string,
  displayName: string,
  isPremium: boolean,
  subscriptionExpirationDate: timestamp,
  revenueCatUserId: string,
  createdAt: timestamp,
  updatedAt: timestamp,
  // Subscription details
  subscriptionProductIdentifier: string,
  subscriptionIsActive: boolean,
  subscriptionPeriodType: string,
  subscriptionStore: string,
  subscriptionIsSandbox: boolean
}

// users/{userId}/chat_sessions/{sessionId}
{
  userId: string,
  title: string,
  createdAt: timestamp,
  updatedAt: timestamp,
  lastMessage: string,
  messageCount: number,
  mood: number
}

// users/{userId}/chat_sessions/{sessionId}/messages/{messageId}
{
  content: string,
  role: "user" | "assistant",
  timestamp: timestamp,
  isEncrypted: boolean,
  encryptedData: string // if encrypted
}

// users/{userId}/journal_entries/{entryId}
{
  content: string,
  type: "freeForm" | "tagged" | "themed",
  tags: array<string>,
  mood: number,
  createdAt: timestamp,
  isEncrypted: boolean
}

// users/{userId}/mood_entries/{entryId}
{
  mood: number, // 1-5 scale
  timestamp: timestamp,
  note: string
}
```

### Security Rules
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{subcollection=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Cloud Functions

#### AI Chat Function (v2)
```typescript
// functions/src/index.ts
export const aiChat = functions
  .runWith({
    memory: '1GB',
    timeoutSeconds: 60,
    secrets: ['OPENAI_API_KEY']
  })
  .https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated');
    
    // Rate limiting (60 requests/minute)
    await checkRateLimit(context.auth.uid);
    
    // OpenAI GPT-4 integration
    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [...contextMessages, { role: 'user', content: data.message }],
      max_tokens: 800,
      temperature: 0.8
    });
    
    // Save to Firestore
    await saveMessage(context.auth.uid, data.sessionId, response);
    
    return { message: response.choices[0].message.content };
  });
```

## 💰 Monetization Architecture

### RevenueCat Integration

#### Configuration
```swift
// RevenueCatManager.swift
API Key: appl_gvOXpZqsFihTaAYrcGjEQBaFNFK
Offering: "Omni New"
Paywall: "Omni_Final"
Products: 
  - Weekly subscription
  - Monthly subscription
  - Yearly subscription
```

#### Hard Paywall Implementation
1. **Onboarding Flow**
   - Welcome → Quick Setup → AI Preview → Paywall
   - No app access without subscription
   - 7-day free trial for all tiers

2. **Subscription Sync**
   - RevenueCat webhook → Firebase Function
   - Real-time subscription status updates
   - Firebase user document synchronization

3. **Receipt Validation**
   - Server-side validation via RevenueCat
   - Automatic retry on network failure
   - Grace period handling

## 📊 Analytics Architecture

### Firebase Analytics Events

#### Conversion Funnel
```swift
// AnalyticsManager.swift
1. app_open
2. welcome_viewed
3. setup_started
4. setup_completed
5. ai_preview_shown
6. paywall_shown
7. trial_started
8. sign_in_completed
9. first_chat_started
```

#### Custom Events
- Chat engagement metrics
- Mood tracking patterns
- Journal usage statistics
- Subscription conversion rates
- Feature adoption tracking

### Performance Monitoring
- Firebase Performance SDK
- Custom traces for critical paths
- Network request monitoring
- App startup time tracking

## 🚀 Deployment & CI/CD

### Build Configuration
```yaml
Xcode Version: 15.0+
Swift Version: 5.9+
Deployment Target: iOS 16.0
Architecture: arm64 (Apple Silicon)
```

### Environment Management
```swift
// Configuration files
- Debug: Development Firebase project
- Release: Production Firebase project
- TestFlight: Production with debug logging
```

### App Store Configuration
```yaml
Bundle ID: com.jns.Omni
Version: 1.1
Build: 26
Category: Health & Fitness
Age Rating: 12+
```

## 🔄 Data Flow Architecture

### Message Flow (User → AI Response)
```
1. User enters message in ChatView
2. ChatService validates and prepares message
3. EncryptionManager encrypts sensitive content
4. Firebase Auth token attached to request
5. Cloud Function receives authenticated request
6. Rate limiter checks request frequency
7. OpenAI API processes with context
8. Response saved to Firestore
9. Real-time listener updates UI
10. Message decrypted and displayed
```

### Subscription Flow
```
1. User views paywall (RevenueCat UI)
2. Selects subscription tier
3. Apple StoreKit processes payment
4. RevenueCat validates receipt
5. Webhook triggers Firebase Function
6. User document updated with premium status
7. App receives real-time update
8. Premium features unlocked
```

## 🛡️ Error Handling & Recovery

### Network Resilience
- Offline message queuing
- Automatic retry with exponential backoff
- Firebase offline persistence
- Cached responses for critical data

### Error Recovery Strategies
```swift
// Error handling patterns
1. Authentication errors → Token refresh → Retry
2. Network errors → Queue operation → Retry when online
3. Subscription errors → Force refresh → Fallback UI
4. AI errors → Fallback response → Log for analysis
```

## 📈 Scalability Considerations

### Current Capacity
- **Firestore**: 1M reads/day free tier
- **Cloud Functions**: 2M invocations/month free
- **OpenAI**: Pay-per-token pricing
- **RevenueCat**: 10k MTR free tier

### Scaling Strategy
1. **Database**: Implement caching layer for frequent reads
2. **Functions**: Use Cloud Run for heavy processing
3. **AI Costs**: Implement response caching for common queries
4. **Analytics**: Batch events to reduce writes

## 🔮 Future Architecture Enhancements

### Planned Features
1. **Voice Mode**
   - OpenAI Whisper for transcription
   - Real-time streaming responses
   - WebRTC for low latency

2. **HealthKit Integration**
   - Mood correlation with health metrics
   - Sleep pattern analysis
   - Activity level tracking

3. **Widget Support**
   - Mood tracking widget
   - Daily prompt widget
   - Quick chat access

4. **Advanced Personalization**
   - ML-based response customization
   - User behavior prediction
   - Content recommendations

## 📚 Technical Dependencies

### Core Dependencies
```swift
// Package Dependencies
- Firebase iOS SDK: 10.19.0
- RevenueCat: 4.31.1
- CryptoKit: System framework
- AuthenticationServices: System framework
```

### Cloud Service Dependencies
- Firebase (Auth, Firestore, Functions, Analytics)
- OpenAI API (GPT-4)
- RevenueCat (IAP management)
- Apple Services (Sign In, StoreKit)

---

*This technical architecture document reflects the current production implementation of OmniAI as of January 2025.*