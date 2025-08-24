# RevenueCat Setup Instructions

## ✅ Completed Setup
1. RevenueCat SDK integrated into iOS app
2. Firebase webhook handler deployed
3. User model updated with subscription fields
4. Premium management system connected

## 🔗 Webhook Configuration

### Your Firebase Webhook URL:
```
https://us-central1-omni-ai-8d5d2.cloudfunctions.net/revenueCatWebhook
```

### Steps to Configure in RevenueCat Dashboard:

1. **Log into RevenueCat Dashboard**
   - Go to https://app.revenuecat.com
   - Select your "Omni" project

2. **Navigate to Webhooks**
   - Go to Project Settings → Integrations → Webhooks
   - Click "Add Webhook"

3. **Configure the Webhook**
   - **URL**: `https://us-central1-omni-ai-8d5d2.cloudfunctions.net/revenueCatWebhook`
   - **Version**: v1.0 (latest)
   - **Events to Send**: Select all or choose:
     - Initial purchase
     - Renewal
     - Cancellation
     - Expiration
     - Billing issues
     - Product change
     - Subscriber alias

4. **Test the Webhook**
   - Click "Send Test Event" in RevenueCat
   - Check Firebase Functions logs to verify receipt

## 📱 Testing the Integration

### Sandbox Testing Setup:
1. **Configure Sandbox Tester**
   - App Store Connect → Users and Access → Sandbox Testers
   - Create a test account if needed

2. **Test on Device**
   - Sign out of production App Store account
   - Build and run app on physical device
   - Sign in with sandbox account when prompted

3. **Test Purchase Flow**
   - Tap any premium feature
   - Complete sandbox purchase
   - Verify premium status updates

### What to Verify:
- [ ] Paywall displays correctly
- [ ] Purchase completes successfully
- [ ] Premium status updates immediately
- [ ] Firebase user document shows subscription
- [ ] Webhook events appear in Firebase logs
- [ ] Restore purchases works correctly

## 🔍 Monitoring

### Firebase Console:
- **Functions Logs**: https://console.firebase.google.com/project/omni-ai-8d5d2/functions/logs
- **Firestore Users**: https://console.firebase.google.com/project/omni-ai-8d5d2/firestore/data/~2Fusers

### RevenueCat Dashboard:
- **Overview**: https://app.revenuecat.com/overview
- **Customers**: View individual subscription status
- **Webhooks**: Monitor webhook delivery status

## 🚀 Production Checklist

Before going live:
- [ ] Products created in App Store Connect
- [ ] Products imported to RevenueCat
- [ ] Paywall configured and published in RevenueCat
- [ ] Webhook URL configured and tested
- [ ] Sandbox testing completed
- [ ] Analytics events configured
- [ ] Error handling tested

## 📝 Important URLs

- **RevenueCat SDK Key**: `appl_pFgbZgVGqzPIeHMXmiyTwUrsXNl`
- **Apple App ID**: `6743356581`
- **Firebase Project**: `omni-ai-8d5d2`
- **Webhook URL**: `https://us-central1-omni-ai-8d5d2.cloudfunctions.net/revenueCatWebhook`

## 🆘 Troubleshooting

### If purchases don't work:
1. Check RevenueCat dashboard for product configuration
2. Verify App Store Connect product status (must be "Ready to Submit" or "Approved")
3. Check Firebase function logs for errors
4. Ensure user is identified to RevenueCat

### If webhook events don't arrive:
1. Check webhook URL is correct in RevenueCat
2. Verify Firebase function is deployed
3. Check Firebase function logs for errors
4. Test with RevenueCat's "Send Test Event" feature