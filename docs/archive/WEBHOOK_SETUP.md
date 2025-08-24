# RevenueCat Webhook Setup Guide

## 🔐 Retrieving Your Webhook Authorization Token

Your webhook authorization token is stored securely in Firebase Secrets Manager. 

### To retrieve it:

```bash
firebase functions:secrets:access REVENUECAT_WEBHOOK_SECRET
```

This will display your Bearer token to copy into RevenueCat.

### RevenueCat Dashboard Configuration:

1. **Webhook Name:** OmniAI Production
2. **Webhook URL:** `https://us-central1-omni-ai-8d5d2.cloudfunctions.net/revenueCatWebhook`
3. **Authorization Header Value:** Run the command above to retrieve
4. **Environment:** Production and Sandbox
5. **App:** Select your OmniAI app
6. **Event type:** All events

## 🔒 Security Best Practices

- **Never store secrets in files** - Even with .gitignore
- **Use Firebase Secrets Manager** - Your token is safely stored there
- **Access only when needed** - Run the command above only when configuring
- **Rotate if compromised** - Use `firebase functions:secrets:set` to update

## 📊 Monitoring

View webhook activity:
- [Function Logs](https://console.firebase.google.com/project/omni-ai-8d5d2/functions/logs?search=revenueCatWebhook)

## 🔄 Rotating the Secret (if needed)

If you ever need to change the authorization token:

1. Generate new token:
   ```bash
   openssl rand -hex 32
   ```

2. Update in Firebase:
   ```bash
   echo "Bearer omni_rcwh_[new_token]" | firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
   ```

3. Redeploy functions:
   ```bash
   cd functions && npm run deploy
   ```

4. Update in RevenueCat dashboard

## ✅ Your Webhook Status

- ✅ Webhook deployed and secured
- ✅ Authorization validation active
- ✅ Secret stored in Firebase Secrets Manager
- ✅ Ready for RevenueCat events

---
Note: This document contains no sensitive information. 
Always retrieve secrets directly from Firebase when needed.