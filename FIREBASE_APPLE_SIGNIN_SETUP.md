# Firebase Apple Sign-In Configuration

## Steps to Configure Apple Sign-In in Firebase Console

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **omni-ai-8d5d2**
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Apple** provider
5. Enable the Apple provider toggle

### 2. Configure Apple Provider Settings

In the Apple configuration dialog, you need to add:

#### Service ID Configuration:
- **Service ID**: `com.jns.Omni.service` (or your preferred service ID)
- **Apple Team ID**: Your Apple Developer Team ID
- **Key ID**: The Key ID from your Apple Developer account
- **Private Key**: (The one you provided - keep this secure!)

```
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgVr0BLoZtqZIBlF04
cjn1fIWY/UHr4J+aPzGnO2Hs2YKgCgYIKoZIzj0DAQehRANCAAQqSj53ipNAnhuW
NLNaKpthhBRRthdC2d5BhX+28a7mQyp4/Cmn18TPCtUXOAJbFlXzV/uPcoAE2vrN
14uvSmVc
```

### 3. Apple Developer Portal Setup

1. Go to [Apple Developer](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**

#### Create/Update App ID:
1. Go to **Identifiers** → Select your App ID (`com.jns.Omni`)
2. Enable **Sign In with Apple** capability
3. Click **Edit** next to Sign In with Apple
4. Choose **Enable as a primary App ID**

#### Create Service ID (if not exists):
1. Go to **Identifiers** → Click **+**
2. Select **Services IDs**
3. Enter:
   - Description: `Omni AI Service`
   - Identifier: `com.jns.Omni.service`
4. Enable **Sign In with Apple**
5. Configure:
   - Primary App ID: `com.jns.Omni`
   - Domains: `omni-ai-8d5d2.firebaseapp.com`
   - Return URLs: `https://omni-ai-8d5d2.firebaseapp.com/__/auth/handler`

#### Create/Update Key:
1. Go to **Keys** → Find your existing key or create new
2. Enable **Sign In with Apple**
3. Configure for your App ID
4. Download the key file (keep it secure!)

### 4. Update Info.plist (Already Done)

Your Info.plist already has the necessary Firebase configuration.

### 5. Xcode Project Settings

1. Open your project in Xcode
2. Select your target → **Signing & Capabilities**
3. Add **Sign In with Apple** capability if not already present
4. Ensure your Team and Bundle Identifier are correct

### 6. Testing

To test Apple Sign-In:
1. Run the app on a real device or simulator
2. Tap "Sign in with Apple"
3. Complete the authentication flow
4. Check Firebase Console → **Authentication** → **Users** tab
5. You should see the new user with Apple provider

## Troubleshooting

### Common Issues:

1. **"Invalid client" error**:
   - Verify Service ID matches in Firebase and Apple Developer
   - Check return URL is exactly: `https://omni-ai-8d5d2.firebaseapp.com/__/auth/handler`

2. **"Sign in with Apple isn't available" error**:
   - Ensure Sign In with Apple capability is added in Xcode
   - Check provisioning profile includes the capability

3. **Users not appearing in Firebase**:
   - Check Firebase project configuration
   - Verify the private key is correctly entered
   - Check console logs for authentication errors

4. **"Unable to fetch identity token" error**:
   - This usually means the nonce isn't being properly set
   - The code has been updated to fix this

## Security Notes

- Never commit the private key to version control
- Store the private key securely in Firebase Console only
- Rotate keys periodically for security
- Use environment-specific Service IDs for production vs development

## Code Implementation Status

✅ Firebase Auth properly configured in AuthenticationManager.swift
✅ Apple Sign-In with nonce implementation for security
✅ Guest session support with Firebase Anonymous Auth
✅ Guest to permanent account conversion
✅ Proper error handling and user feedback
✅ Firestore user profile creation and updates

## Next Steps

1. Configure Apple Sign-In in Firebase Console with the settings above
2. Test the authentication flow
3. Verify users appear in Firebase Console
4. Monitor authentication analytics in Firebase