# App Store Submission Checklist

## Current Version Info
- **Version Number**: 1.1
- **Build Number**: 26
- **Bundle ID**: com.jns.Omni

## Pre-Archive Checklist

### ✅ Completed Changes
1. ✅ Simplified to hard paywall model
2. ✅ Removed all premium badges and locks
3. ✅ Fixed navigation after payment
4. ✅ Removed daily message limits
5. ✅ Updated build number to 26

### 📱 Archive in Xcode

1. **Select Generic iOS Device**
   - Change scheme from simulator to "Any iOS Device (arm64)"

2. **Archive the App**
   - Product → Archive
   - Wait for build to complete

3. **Fix Code Signing (if needed)**
   - In Signing & Capabilities:
   - Team: Select your Apple Developer team
   - Provisioning Profile: Automatic
   - Code Signing Identity: Apple Development (for now)
   - For Release: Will switch to Apple Distribution automatically

4. **Validate Archive**
   - Window → Organizer
   - Select your archive
   - Click "Validate App"
   - Follow prompts to validate

5. **Upload to App Store Connect**
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Select "Upload"
   - Follow prompts

## App Store Connect Setup

### What's New in Version 1.1
```
• Simplified onboarding experience with AI preview
• Hard paywall model with 7-day free trial
• Enhanced security with client-side encryption
• Improved chat experience with GPT-4
• Advanced analytics and mood tracking
• Better RevenueCat integration
• Fixed authentication and navigation issues
```

### Review Notes
```
This is a mental health support app using OpenAI's GPT-4 API for therapeutic conversations.

Testing Instructions:
1. Complete onboarding flow with mood/goal selection
2. View AI preview demonstration
3. Subscribe via 7-day free trial (required for app access)
4. Sign in with Apple or create email account
5. Access all features including chat, journal, and mood tracking

Technical Details:
- Firebase backend (project: omni-ai-8d5d2)
- RevenueCat Integration: "Omni New" offering
- Paywall: "Omni_Final" identifier
- Hard paywall model (subscription required upfront)
- Client-side AES-256 encryption for sensitive data
- Analytics via Firebase Analytics
```

### Subscription Details
Make sure these are configured in App Store Connect:
- Weekly subscription
- Monthly subscription  
- Yearly subscription
- 7-day free trial for all tiers

## Post-Submission

1. **Monitor Review Status**
   - Check App Store Connect regularly
   - Respond quickly to any reviewer questions

2. **Prepare for Release**
   - Plan marketing announcement
   - Update website/landing page
   - Prepare support documentation

## Important Notes

- The app uses a hard paywall model - users must subscribe to use any features
- All premium locks have been removed from the codebase
- RevenueCat manages all subscription logic with "Omni New" offering
- Firebase (omni-ai-8d5d2) handles user data and chat history
- Build 26 includes enhanced security and analytics
- Client-side encryption protects sensitive user data

## App Store Keywords (Suggested)
- mental health app
- AI therapy
- anxiety support
- mood tracking
- depression help
- journal therapy
- mental wellness
- therapeutic chat
- emotional support
- mindfulness app

## Category Selection
- Primary: Health & Fitness
- Secondary: Medical

Good luck with your submission! 🚀