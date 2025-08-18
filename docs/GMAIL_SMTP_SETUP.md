# Gmail SMTP Configuration for OmniAI

## ⚠️ Important: Gmail App Password Required

Gmail requires an **App Password** for SMTP authentication, not your regular Gmail password. Follow these steps to set it up correctly.

## Step 1: Enable 2-Factor Authentication (Required)

1. Go to your [Google Account settings](https://myaccount.google.com/)
2. Navigate to **Security** in the left sidebar
3. Under "How you sign in to Google", click **2-Step Verification**
4. Follow the prompts to enable 2FA if not already enabled

## Step 2: Generate App Password

1. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
   - Or navigate: Google Account → Security → 2-Step Verification → App passwords
2. Select **Mail** from the "Select app" dropdown
3. Select **Other (Custom name)** from the "Select device" dropdown
4. Enter **"OmniAI Supabase"** as the custom name
5. Click **Generate**
6. **COPY THE 16-CHARACTER PASSWORD** (it looks like: `abcd efgh ijkl mnop`)
   - Remove spaces when using it
   - You won't be able to see this password again!

## Step 3: Configure Supabase SMTP Settings

In your [Supabase Dashboard SMTP Settings](https://supabase.com/dashboard/project/rchropdkyqpfyjwgdudv/settings/auth):

### Enable Custom SMTP
Toggle ON: **Enable Custom SMTP** ✅

### Sender Details
- **Sender email**: `omniappofficial@gmail.com`
- **Sender name**: `Omni AI`

### SMTP Provider Settings
- **Host**: `smtp.gmail.com`
- **Port number**: `587`
- **Minimum interval between emails**: `60` seconds
- **Username**: `omniappofficial@gmail.com`
- **Password**: `[YOUR 16-CHARACTER APP PASSWORD WITHOUT SPACES]`
  - Example: If Google gave you `abcd efgh ijkl mnop`, enter: `abcdefghijklmnop`

### Important Notes
- ✅ Use port **587** (TLS) - Most reliable with Gmail
- ❌ Don't use port 465 (SSL) - Can have issues
- ❌ Don't use port 25 - Often blocked

## Step 4: Test Your Configuration

1. Click **Save changes** in Supabase
2. Try signing up with a new email address in your app
3. Check the email inbox for the verification email
4. Check spam/junk folder if not in inbox

## Troubleshooting

### If emails aren't sending:

1. **Verify App Password is correct**
   - No spaces in the password
   - All lowercase letters
   - Exactly 16 characters

2. **Check Google Security**
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Look for any security alerts about blocked sign-in attempts
   - If blocked, click "Yes, it was me" to allow the connection

3. **Less Secure Apps (Not Recommended)**
   - This option is deprecated and should not be used
   - App Passwords are the correct method

### Common Errors and Solutions

| Error | Solution |
|-------|----------|
| "Invalid credentials" | Regenerate app password and ensure no spaces |
| "Authentication failed" | Check 2FA is enabled and app password is correct |
| "Connection timeout" | Try port 587 instead of 465 |
| "Less secure app blocked" | Use App Password, not regular password |

## Alternative: Use a Professional Email Service

For production, consider using:
- **SendGrid** - 100 emails/day free
- **AWS SES** - $0.10 per 1000 emails
- **Resend** - 100 emails/day free
- **Postmark** - 100 emails/month free

These services are more reliable and have better deliverability than Gmail SMTP.

## Security Best Practices

1. **Never commit SMTP credentials to git**
2. **Use environment variables for production**
3. **Rotate app passwords periodically**
4. **Monitor for unusual activity**
5. **Set up SPF/DKIM records for your domain** (if using custom domain)