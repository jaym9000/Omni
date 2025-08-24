# RevenueCat Integration Documentation

## Overview
This document describes the complete RevenueCat integration for OmniAI, including subscription management, webhook handling, and security implementation.

## 🏗️ Architecture

### iOS App Components
- **RevenueCatManager.swift** - Core SDK integration service
- **PaywallView.swift** - RevenueCat paywall UI wrapper
- **PremiumManager.swift** - Premium feature access control
- **SubscriptionManagementView.swift** - User subscription management UI

### Backend Components
- **Firebase Function: `revenueCatWebhook`** - Processes subscription events
- **Firestore Collections** - Stores user subscription status
- **Firebase Secrets Manager** - Stores webhook authorization token

## 🔐 Security Implementation

### Webhook Authorization
The webhook endpoint is secured with Bearer token authentication:

1. **Token Storage Locations:**
   - **Primary:** Firebase Secrets Manager (`REVENUECAT_WEBHOOK_SECRET`)
   - **Local Backup:** macOS Keychain (service: `OmniAI-Webhook-Token`)

2. **Token Retrieval Commands:**
   ```bash
   # From Firebase (requires project access)
   firebase functions:secrets:access REVENUECAT_WEBHOOK_SECRET
   
   # From macOS Keychain (local machine only)
   security find-generic-password -a "RevenueCat" -s "OmniAI-Webhook-Token" -w
   ```

3. **Security Features:**
   - All webhook requests validated against stored token
   - Unauthorized requests return 401
   - Failed attempts logged for monitoring
   - Token never stored in source code or plain text files

### User Authentication Flow
1. User signs in (Firebase Auth)
2. RevenueCat SDK identifies user with Firebase UID
3. Subscription status synced between RevenueCat and Firebase
4. Premium features unlocked based on entitlements

## 📱 iOS Implementation

### SDK Initialization
- **Location:** `OmniAIApp.swift`
- **API Key:** Stored in source code (safe - it's public)
- **Timing:** On app launch in AppDelegate

### Subscription Features
- **Monthly:** `omni_premium_monthly`
- **Yearly:** `omni_premium_yearly`
- **Lifetime:** `omni_premium_lifetime`

### Entitlement
- **Name:** `premium`
- **Access:** All premium features with single entitlement

### Premium Features Controlled
1. Unlimited AI chat messages
2. Voice mode
3. Tagged journal entries
4. Themed journal prompts
5. Anxiety management tools
6. Advanced analytics
7. Data export

## 🔄 Webhook Processing

### Endpoint
```
https://us-central1-omni-ai-8d5d2.cloudfunctions.net/revenueCatWebhook
```

### Supported Events
- `INITIAL_PURCHASE` - First subscription
- `RENEWAL` - Subscription renewed
- `CANCELLATION` - User cancelled
- `EXPIRATION` - Subscription expired
- `BILLING_ISSUE` - Payment problem
- `PRODUCT_CHANGE` - Plan change
- `SUBSCRIBER_ALIAS` - User account merge

### Data Flow
1. RevenueCat sends webhook to Firebase Function
2. Function validates authorization header
3. Updates user document in Firestore
4. iOS app receives real-time update via Firestore listener

## 📊 Monitoring & Debugging

### Firebase Console
- **Function Logs:** [View Logs](https://console.firebase.google.com/project/omni-ai-8d5d2/functions/logs)
- **Search for:** `RevenueCat webhook received`
- **Monitor:** Unauthorized attempts, processing errors

### RevenueCat Dashboard
- **Webhook Status:** Settings → Integrations → Webhooks
- **Delivery History:** Shows success/failure for each event
- **Test Events:** Send test webhook to verify integration

### Local Testing
```bash
# View recent webhook logs
firebase functions:log --only revenueCatWebhook

# Test webhook locally (requires ngrok)
npm run serve # In functions directory
```

## 🚨 Troubleshooting

### Common Issues

1. **Webhook Not Receiving Events**
   - Verify authorization header in RevenueCat matches stored secret
   - Check Firebase Function is deployed and running
   - Confirm webhook URL is correct

2. **User Not Getting Premium Access**
   - Check RevenueCat customer page for active entitlements
   - Verify user identification (Firebase UID matches RevenueCat)
   - Review Firestore user document for subscription fields

3. **401 Unauthorized Errors**
   - Authorization token mismatch
   - Retrieve correct token from Firebase Secrets or Keychain
   - Update in RevenueCat dashboard

### Debug Commands
```bash
# Check if secret exists
firebase functions:secrets:get REVENUECAT_WEBHOOK_SECRET

# View function status
firebase functions:list

# Check recent errors
firebase functions:log --only revenueCatWebhook --severity ERROR
```

## 🔄 Updating Credentials

### If Token Needs Rotation:
1. Generate new token:
   ```bash
   openssl rand -hex 32
   ```

2. Update Firebase secret:
   ```bash
   echo "Bearer omni_rcwh_[new_token]" | firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
   ```

3. Update local Keychain:
   ```bash
   security delete-generic-password -a "RevenueCat" -s "OmniAI-Webhook-Token"
   security add-generic-password -a "RevenueCat" -s "OmniAI-Webhook-Token" -w "Bearer omni_rcwh_[new_token]"
   ```

4. Redeploy function:
   ```bash
   cd functions && npm run deploy
   ```

5. Update RevenueCat dashboard with new token

## 📝 Configuration Checklist

### RevenueCat Dashboard
- [x] Products created and imported
- [x] Entitlements configured
- [x] Paywall published
- [x] Webhook configured with authorization
- [x] Events set to "All events"
- [x] Environment set to "Production and Sandbox"

### Firebase
- [x] Webhook function deployed
- [x] Secret stored in Secrets Manager
- [x] IAM permissions configured
- [x] Firestore indexes created

### iOS App
- [x] RevenueCat SDK integrated
- [x] API key configured
- [x] User identification implemented
- [x] Paywall UI integrated
- [x] Subscription management UI added

## 🔗 Important Links

- **RevenueCat Dashboard:** [app.revenuecat.com](https://app.revenuecat.com)
- **Firebase Console:** [console.firebase.google.com](https://console.firebase.google.com/project/omni-ai-8d5d2)
- **App Store Connect:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

## 📅 Maintenance Schedule

### Daily
- Monitor webhook delivery in RevenueCat dashboard
- Check for billing issues in customer list

### Weekly
- Review subscription metrics
- Check for failed webhook deliveries
- Monitor conversion rates

### Monthly
- Rotate webhook token (optional but recommended)
- Review and optimize paywall performance
- Audit subscription status sync

## 🛡️ Security Best Practices

1. **Never commit secrets** - Use Firebase Secrets and Keychain
2. **Rotate tokens regularly** - Monthly rotation recommended
3. **Monitor unauthorized attempts** - Check logs for 401 errors
4. **Limit access** - Only authorized team members should access secrets
5. **Use secure channels** - Share credentials only via password managers

---

*Last Updated: 2025-08-22*
*This document contains no sensitive information and is safe to commit to version control.*