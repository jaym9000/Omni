# OpenAI Edge Function Deployment Guide

## Security Architecture

This implementation ensures **maximum security** for your mental health therapy app:

✅ **API Key Security**: OpenAI API key stored server-side only (never in iOS app)  
✅ **JWT Authentication**: All requests authenticated via Supabase Auth  
✅ **Crisis Detection**: Automatic detection and intervention for mental health emergencies  
✅ **HIPAA Considerations**: Privacy-focused logging and data handling  
✅ **Fallback Support**: Graceful degradation if AI service fails  

## Prerequisites

1. **Supabase CLI installed**:
   ```bash
   npm install -g supabase
   ```

2. **Supabase project linked**:
   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **OpenAI API Key** (you'll set this as a secret)

## Deployment Steps

### Step 1: Deploy the Edge Function

```bash
# Navigate to your project directory
cd /Users/jm/Desktop/Projects-2025/Omni

# Deploy the ai-chat Edge Function
supabase functions deploy ai-chat
```

### Step 2: Set OpenAI API Key as Secret

**CRITICAL**: Store your OpenAI API key securely as a Supabase secret:

```bash
# Set your OpenAI API key (replace with your actual key)
supabase secrets set OPENAI_API_KEY=sk-your-actual-openai-key-here
```

### Step 3: Run Crisis Logging Database Migration

```bash
# Apply the crisis logging extension
supabase db push
```

Or manually run the SQL in your Supabase dashboard:
```sql
-- Copy contents of supabase_crisis_extension.sql and run in SQL Editor
```

### Step 4: Test Edge Function

```bash
# Test the deployed function
curl -L -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/ai-chat' \
  -H 'Authorization: Bearer YOUR_USER_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  --data '{"message":"Hello, I feel anxious today","sessionId":"test-session-123"}'
```

### Step 5: Verify iOS Integration

The iOS app is already updated to call the Edge Function. Test by:

1. **Build and run** the app in Xcode
2. **Sign in** with a test account
3. **Start a chat** and send a message
4. **Verify** AI responses come from OpenAI (not mock responses)

## Security Features Implemented

### 🔒 Server-Side API Key Storage
- OpenAI API key stored as Supabase Edge Function secret
- Never exposed to client-side code
- Rotatable without app updates

### 🛡️ Authentication & Authorization
- JWT token validation on every request
- User context verification via Supabase Auth
- Request rate limiting (inherent in Edge Functions)

### 🚨 Crisis Detection & Safety
- **Keyword Detection**: Scans for suicide/self-harm language
- **Crisis Levels**: 0-10 scale for intervention decisions
- **Immediate Response**: High-risk messages get crisis resources
- **Safety Logging**: Anonymous crisis detection logging for monitoring
- **Professional Resources**: National hotlines and text lines provided

### 🏥 HIPAA Compliance Considerations
- **Minimal Data Storage**: Only essential conversation data stored
- **User Isolation**: RLS policies ensure data separation
- **Crisis Privacy**: Crisis logs are admin-only, not user-accessible
- **Audit Trail**: All AI interactions logged for safety monitoring

## Edge Function Features

### Therapeutic System Prompt
- Evidence-based mental health support guidelines
- Clear boundaries about not replacing professional therapy
- Warm, empathetic, non-judgmental communication style
- Crisis escalation protocols built-in

### Mood-Aware Responses
- Contextual prompts based on user's current mood
- Specialized guidance for anxiety, depression, stress
- Personalized coping strategy suggestions

### Conversation Continuity
- Maintains last 10 messages for context
- Session-aware responses
- Conversation history stored securely in Supabase

### Graceful Fallbacks
- Supportive responses if OpenAI API fails
- Local message storage if database connection issues
- Never leaves user without response

## Cost Management

### OpenAI Usage Optimization
- **Model**: GPT-4 Turbo (balance of quality and cost)
- **Token Limits**: 500 max tokens per response
- **Context Window**: Limited to last 10 messages
- **Temperature**: 0.7 for balanced creativity/consistency

### Expected Costs (Estimates)
- **Light Usage**: ~$5-10/month (100 messages/day)
- **Medium Usage**: ~$25-50/month (500 messages/day)
- **Heavy Usage**: ~$100-200/month (2000 messages/day)

*Crisis interventions bypass all rate limiting for safety*

## Monitoring & Maintenance

### Key Metrics to Monitor
1. **Edge Function Performance**: Response times, error rates
2. **Crisis Detection Rate**: Frequency of crisis interventions
3. **OpenAI API Usage**: Token consumption, costs
4. **User Engagement**: Messages per session, return usage

### Health Checks
- Edge Function automatically monitored by Supabase
- OpenAI API status integrated in function error handling
- Database connectivity verified on each request

### Alerts to Set Up
1. **High Crisis Detection**: Unusual spike in crisis interventions
2. **OpenAI API Failures**: Service degradation alerts
3. **Cost Thresholds**: Monthly spending limits
4. **Function Errors**: Edge Function failure notifications

## Testing Scenarios

### 1. Normal Conversation
```json
{
  "message": "I had a stressful day at work",
  "sessionId": "test-123",
  "mood": "stressed"
}
```

### 2. Crisis Detection (Test Safely)
```json
{
  "message": "I'm having thoughts of ending it all",
  "sessionId": "test-123"
}
```
*Should return crisis resources and hotlines*

### 3. Mood-Specific Support
```json
{
  "message": "I can't stop feeling anxious",
  "sessionId": "test-123",
  "mood": "anxious"
}
```

## Troubleshooting

### Common Issues

**"OpenAI API key not configured"**
- Run: `supabase secrets set OPENAI_API_KEY=your-key`
- Redeploy: `supabase functions deploy ai-chat`

**"Invalid token" errors**
- Verify user is signed in to app
- Check Supabase Auth configuration
- Test with fresh user session

**Edge Function timeouts**
- Check OpenAI API status
- Monitor function logs: `supabase functions logs ai-chat`
- Verify network connectivity

### Debug Commands

```bash
# View Edge Function logs
supabase functions logs ai-chat --no-follow

# Check current secrets
supabase secrets list

# Test local function
supabase functions serve ai-chat
```

## Next Steps

1. **Deploy and test** the Edge Function
2. **Monitor crisis detection** in production
3. **Set up cost alerts** for OpenAI usage
4. **Consider crisis team integration** for high-risk situations
5. **Plan crisis intervention UI** for the iOS app

This implementation provides the **most secure** possible integration of OpenAI into your mental health app, with your API key safely stored server-side and comprehensive safety measures for vulnerable users.