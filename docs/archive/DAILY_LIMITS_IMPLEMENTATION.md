# Daily Message Limits & Paywall Implementation

## Overview
Implemented a robust daily message limit system (10 messages/day) for free/guest users with paywall placeholders for premium features, fully compliant with Apple's App Store guidelines.

## Key Features Implemented

### 1. Daily Message Limits (10/day)
- **Server-side tracking**: Message count stored in Firestore by Firebase UID
- **Automatic reset**: Count resets at midnight (server time)
- **Sign-out protection**: Daily count persists even if user signs out and back in
- **Real-time UI updates**: Shows remaining messages in chat interface

### 2. Paywall System
Premium features now show lock icons and trigger paywall when tapped:
- **Voice Chat**: Lock icon on voice tab, shows paywall when tapped
- **Journal Features**: Tagged entries and themed prompts require premium
- **Anxiety Management**: Full anxiety card locked for free users
- **Free Features**: Chat (10/day) and free-form journaling remain accessible

### 3. Apple Guidelines Compliance
- ✅ **No device fingerprinting** - Uses Firebase UID only
- ✅ **No IDFA tracking** - No advertising identifiers used
- ✅ **Privacy-first approach** - All tracking tied to authenticated session
- ✅ **Transparent limits** - Clear messaging about daily limits

## Technical Implementation

### Backend Changes
1. **Firebase Function (aiChat)**
   - Tracks `dailyMessageCount` and `lastMessageDate` per user
   - Automatically resets count when date changes
   - Returns 429 status when daily limit reached
   - Provides hours until reset in response

2. **Firestore Structure**
   ```javascript
   users/{userId}: {
     dailyMessageCount: 0-10,
     lastMessageDate: Timestamp,
     maxDailyMessages: 10,
     isPremium: boolean
   }
   ```

### iOS App Changes
1. **PaywallView Component**
   - Reusable component for all premium features
   - Shows current usage and daily limit
   - Animated lock icons and progress bars
   - Clear upgrade CTAs

2. **Updated Views**
   - **ChatView**: Voice tab shows lock, daily counter visible
   - **JournalView**: Premium options show lock icons
   - **HomeView**: Anxiety card displays lock for free users

3. **User Model Updates**
   - Added `dailyMessageCount`, `lastMessageDate`, `maxDailyMessages`
   - Backward compatible with existing user data

## How It Works

### Daily Limit Flow
1. User sends message → Function checks daily count
2. If under limit → Process message, increment count
3. If at limit → Return 429 error with reset time
4. At midnight → Count automatically resets to 0

### Paywall Flow
1. User taps premium feature → Check `isPremium` status
2. If not premium → Show PaywallView overlay
3. Display feature benefits and upgrade CTA
4. Track which feature triggered paywall for analytics

## Security Considerations

### Prevents Common Workarounds
- ✅ **Sign-out/Sign-in**: Count tied to Firebase UID, persists across sessions
- ✅ **Multiple devices**: Same UID = same daily limit across all devices
- ✅ **Time zone manipulation**: Server-side time used for reset
- ✅ **Client-side tampering**: All validation done server-side

### Limitations (By Design)
- App uninstall/reinstall creates new anonymous UID (new 10 messages)
- Different sign-in methods (email, Apple, Google) get separate limits
- No IP-based tracking (privacy-first approach)

## Testing

### Manual Testing Steps
1. Launch app as guest
2. Send 10 messages to hit daily limit
3. Verify error message and remaining time
4. Sign out and back in - count should persist
5. Test each paywall trigger (voice, journal, anxiety)
6. Wait for midnight reset or test with date change

### Automated Tests
```bash
# Test daily limits
./Scripts/test-daily-limits.sh

# Test guest chat flow
./Scripts/test-guest-chat.sh
```

## Deployment

### Firebase Functions
```bash
firebase deploy --only functions:aiChat
```

### iOS App
1. Build and archive in Xcode
2. Upload to TestFlight
3. Test paywall displays correctly
4. Submit for App Store review

## Future Enhancements

1. **Analytics Integration**
   - Track paywall conversion rates
   - Monitor daily limit reach frequency
   - A/B test different message limits

2. **Subscription Integration**
   - RevenueCat or StoreKit 2 implementation
   - Receipt validation via Firebase Functions
   - Automatic premium status updates

3. **Progressive Limits**
   - Start with 10 messages, reduce over time
   - Offer one-time limit increases
   - Weekly/monthly quotas for engaged users

## Metrics to Track

- Daily active users hitting limit
- Paywall view → conversion rate
- Feature-specific upgrade triggers
- User retention after limit reached
- Sign-up rate from guest users

## Support Considerations

Common user questions:
- "Why can't I send more messages?" → Daily limit explanation
- "I signed out but still limited" → Working as intended
- "When does my limit reset?" → Midnight server time
- "How do I get unlimited?" → Upgrade to premium

## Compliance Notes

- Fully compliant with Apple App Store Review Guidelines 5.6.2
- No fingerprinting or tracking beyond authenticated session
- Clear disclosure of limits and premium features
- Respects user privacy while preventing abuse