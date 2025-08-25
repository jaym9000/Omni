# App Store Privacy Details Guide for OmniAI

This document provides the necessary information for completing the App Store Connect privacy details section.

## Privacy Policy URL
`https://omniai.app/privacy` (Update with your actual URL)

## Data Types Collected

### 1. Contact Info
- **Email Address**
  - ✅ Collected
  - Purpose: Account Management, App Functionality
  - Linked to Identity: Yes
  - Used for Tracking: No

### 2. User Content
- **Photos or Videos**
  - ❌ Not Collected

- **Audio Data**
  - ❌ Not Collected (Voice mode UI exists but not functional)

- **Other User Content**
  - ✅ Collected (Chat messages, Journal entries)
  - Purpose: App Functionality
  - Linked to Identity: Yes
  - Used for Tracking: No

### 3. Health & Fitness
- **Health**
  - ✅ Collected (Mood tracking, mental health conversations)
  - Purpose: App Functionality, Analytics
  - Linked to Identity: Yes
  - Used for Tracking: No

### 4. Identifiers
- **User ID**
  - ✅ Collected (Firebase Auth UID)
  - Purpose: App Functionality, Account Management
  - Linked to Identity: Yes
  - Used for Tracking: No

### 5. Usage Data
- **Product Interaction**
  - ✅ Collected (Feature usage, session duration)
  - Purpose: Analytics, Product Personalization
  - Linked to Identity: Yes
  - Used for Tracking: No

- **Crash Data**
  - ✅ Collected (Via Firebase Crashlytics)
  - Purpose: App Functionality
  - Linked to Identity: No
  - Used for Tracking: No

- **Performance Data**
  - ✅ Collected (App performance metrics)
  - Purpose: App Functionality
  - Linked to Identity: No
  - Used for Tracking: No

### 6. Diagnostics
- **Other Diagnostic Data**
  - ✅ Collected (Error logs, debug information)
  - Purpose: App Functionality
  - Linked to Identity: No
  - Used for Tracking: No

### 7. Purchases
- **Purchase History**
  - ✅ Collected (Via RevenueCat/App Store)
  - Purpose: App Functionality
  - Linked to Identity: Yes
  - Used for Tracking: No

### 8. Sensitive Info
- **Sensitive Info**
  - ✅ Collected (Mental health data)
  - Purpose: App Functionality
  - Linked to Identity: Yes
  - Used for Tracking: No

## Data Not Collected

### Financial Info
- Payment Info: ❌ (Handled by Apple)
- Credit Info: ❌
- Other Financial Info: ❌

### Location
- Precise Location: ❌
- Coarse Location: ❌

### Contacts
- Contacts: ❌

### Browsing History
- Browsing History: ❌
- Search History: ❌ (except in-app searches)

### Other Data Types
- Physical Address: ❌
- Phone Number: ❌
- Emails or Text Messages: ❌
- Gameplay Content: ❌
- Customer Support: ❌
- Other Data Types: ❌

## Privacy Practices

### Data Use
All collected data is used for:
1. **App Functionality** - Core features
2. **Analytics** - Improving the app
3. **Account Management** - User authentication
4. **Product Personalization** - AI responses

### Data Linked to You
The following data is linked to your identity:
- Email Address
- User Content (chats, journals)
- Health Data (mood tracking)
- User ID
- Usage Data
- Purchase History
- Sensitive Info

### Data Not Linked to You
The following data is NOT linked to your identity:
- Crash Data
- Performance Data
- Diagnostic Data

### Data Used to Track You
**None** - We do not use any data to track users across apps or websites owned by other companies.

## Third-Party Data Collection
The app uses the following third-party SDKs that may collect data:
- Firebase (Google)
- RevenueCat
- OpenAI API (server-side only)

## Security Measures
- AES-256 encryption for sensitive data
- Secure storage in iOS Keychain
- Firebase security rules
- HTTPS/TLS for all communications

## Age Restriction
- **Age Rating**: 12+ (Infrequent/Mild Medical/Treatment Information)
- **Actual Requirement**: 13+ (COPPA compliance)

## Privacy Contact
- **Email**: privacy@omniai.app
- **Support**: support@omniai.app

## Important Notes for App Review

1. **Mental Health Data**: Emphasize that the app provides supportive AI conversations, not medical treatment
2. **Encryption**: Highlight the AES-256 encryption for sensitive messages
3. **Data Deletion**: Users can delete their account and all associated data
4. **No Tracking**: We do not track users across apps or websites
5. **RevenueCat**: Subscription management is handled by RevenueCat, which has its own privacy practices

## Privacy Labels Summary

When filling out App Store Connect:

### "Does your app collect any data from this app?"
**Yes**

### Categories to Select:
1. ✅ Contact Info (Email)
2. ✅ Health & Fitness (Mental health data)
3. ✅ Identifiers (User ID)
4. ✅ Usage Data (Analytics)
5. ✅ Diagnostics (Crash/Performance)
6. ✅ Purchases (Subscriptions)
7. ✅ User Content (Messages, Journals)
8. ✅ Sensitive Info (Mental health)

### For Each Category:
- **Linked to Identity**: Yes (except Diagnostics)
- **Used for Tracking**: No (for all categories)
- **Purpose**: App Functionality, Analytics

## Compliance Checklist

- [x] GDPR compliant (EU)
- [x] CCPA compliant (California)
- [x] COPPA compliant (13+)
- [x] Apple Guidelines compliant
- [x] Encryption implemented
- [x] User data deletion available
- [x] Privacy policy accessible
- [x] No third-party tracking

## Recent Security Enhancements

### Build 29 Security Updates
- Implemented Firebase App Check for API protection
- Added certificate pinning to prevent MITM attacks
- Integrated jailbreak detection for device security
- Enhanced biometric authentication support
- Implemented comprehensive input validation
- Added content moderation for user safety
- Enhanced encryption with end-to-end message security

---

**Last Updated**: January 25, 2025
**Version**: 1.1 (Build 29)