# Email Template Configuration for OmniAI

## Overview
Configure these email templates in your Supabase Dashboard to enable proper email verification and authentication flows.

## Access Email Templates
1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/rchropdkyqpfyjwgdudv/auth/templates)
2. Navigate to **Authentication** → **Email Templates**

## Required Templates

### 1. Confirm Signup Template
**Subject:** Welcome to OmniAI - Confirm Your Email

**Body:**
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #7FB069; font-size: 28px; margin: 0;">Welcome to OmniAI! 🌟</h1>
  </div>
  
  <div style="background: #F9F7F4; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <h2 style="color: #3A3D42; font-size: 20px; margin-top: 0;">Confirm Your Email</h2>
    <p style="color: #6B7280; font-size: 16px; line-height: 1.5;">
      Thank you for joining OmniAI, your safe space for mental wellness. 
      Please confirm your email address to complete your registration.
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="display: inline-block; background: linear-gradient(to right, #7FB069, #9CC088); color: white; text-decoration: none; padding: 14px 32px; border-radius: 28px; font-weight: 600; font-size: 16px;">
        Confirm Email Address
      </a>
    </div>
    
    <p style="color: #9CA3AF; font-size: 14px; text-align: center;">
      Or use this code: <strong style="color: #3A3D42;">{{ .Token }}</strong>
    </p>
  </div>
  
  <p style="color: #9CA3AF; font-size: 12px; text-align: center;">
    If you didn't create an account with OmniAI, you can safely ignore this email.
  </p>
</div>
```

### 2. Reset Password Template
**Subject:** Reset Your OmniAI Password

**Body:**
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #7FB069; font-size: 28px; margin: 0;">Password Reset Request</h1>
  </div>
  
  <div style="background: #F9F7F4; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <p style="color: #6B7280; font-size: 16px; line-height: 1.5;">
      We received a request to reset your password for your OmniAI account.
      Click the button below to create a new password.
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="display: inline-block; background: linear-gradient(to right, #7FB069, #9CC088); color: white; text-decoration: none; padding: 14px 32px; border-radius: 28px; font-weight: 600; font-size: 16px;">
        Reset Password
      </a>
    </div>
    
    <p style="color: #9CA3AF; font-size: 14px;">
      This link will expire in 1 hour for security reasons.
    </p>
  </div>
  
  <p style="color: #9CA3AF; font-size: 12px; text-align: center;">
    If you didn't request a password reset, you can safely ignore this email.
  </p>
</div>
```

### 3. Magic Link Template
**Subject:** Your OmniAI Sign-In Link

**Body:**
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #7FB069; font-size: 28px; margin: 0;">Sign In to OmniAI</h1>
  </div>
  
  <div style="background: #F9F7F4; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <p style="color: #6B7280; font-size: 16px; line-height: 1.5;">
      Click the button below to securely sign in to your OmniAI account.
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="display: inline-block; background: linear-gradient(to right, #7FB069, #9CC088); color: white; text-decoration: none; padding: 14px 32px; border-radius: 28px; font-weight: 600; font-size: 16px;">
        Sign In to OmniAI
      </a>
    </div>
    
    <p style="color: #9CA3AF; font-size: 14px; text-align: center;">
      Or use this code: <strong style="color: #3A3D42;">{{ .Token }}</strong>
    </p>
    
    <p style="color: #9CA3AF; font-size: 14px;">
      This link will expire in 1 hour for security reasons.
    </p>
  </div>
  
  <p style="color: #9CA3AF; font-size: 12px; text-align: center;">
    If you didn't request this sign-in link, you can safely ignore this email.
  </p>
</div>
```

### 4. Change Email Address Template
**Subject:** Confirm Your New Email Address

**Body:**
```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 30px;">
    <h1 style="color: #7FB069; font-size: 28px; margin: 0;">Confirm Email Change</h1>
  </div>
  
  <div style="background: #F9F7F4; border-radius: 12px; padding: 30px; margin-bottom: 20px;">
    <p style="color: #6B7280; font-size: 16px; line-height: 1.5;">
      You requested to change your email address to <strong>{{ .NewEmail }}</strong>.
      Please confirm this change by clicking the button below.
    </p>
    
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="display: inline-block; background: linear-gradient(to right, #7FB069, #9CC088); color: white; text-decoration: none; padding: 14px 32px; border-radius: 28px; font-weight: 600; font-size: 16px;">
        Confirm Email Change
      </a>
    </div>
    
    <p style="color: #9CA3AF; font-size: 14px;">
      This link will expire in 1 hour for security reasons.
    </p>
  </div>
  
  <p style="color: #9CA3AF; font-size: 12px; text-align: center;">
    If you didn't request this change, please contact support immediately.
  </p>
</div>
```

## Configuration Settings

### Redirect URLs
Add these URLs to your [Redirect URLs configuration](https://supabase.com/dashboard/project/rchropdkyqpfyjwgdudv/auth/url-configuration):

- `omniai://auth-callback` (for iOS app deep linking)
- `https://your-domain.com/auth/callback` (if you have a web app)

### Email Settings
1. **Enable email confirmations** for sign-ups
2. **Set SMTP settings** if you want to use a custom email provider (recommended for production)
3. **Configure rate limits** to prevent abuse

## Testing
After configuring the templates:
1. Test sign-up flow with a new email
2. Test password reset flow
3. Test magic link sign-in
4. Verify emails are received with proper formatting

## Notes
- The templates use OmniAI's therapeutic color scheme (#7FB069 sage green, #F9F7F4 warm cream)
- All templates include both link and OTP code options for flexibility
- Templates are designed to be calming and reassuring for mental health app users