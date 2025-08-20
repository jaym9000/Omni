# OmniAI Firebase Functions

This directory contains the Firebase Cloud Functions for the OmniAI mental health companion app.

## Setup

1. **Install dependencies:**
   ```bash
   cd functions
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   firebase functions:config:set openai.api_key="YOUR_OPENAI_API_KEY"
   ```

3. **Build the functions:**
   ```bash
   npm run build
   ```

## Development

### Run locally with emulators:
```bash
npm run serve
```

### Deploy to Firebase:
```bash
npm run deploy
```

### View logs:
```bash
npm run logs
```

## Available Functions

### HTTP Functions
- `aiChat` - Main chat endpoint for AI conversations
  - Handles OpenAI integration
  - Enforces guest user limits
  - Detects crisis situations
  - Saves conversation history

### Callable Functions
- `createChatSession` - Creates a new chat session
- `getUserSessions` - Retrieves user's chat sessions
- `deleteChatSession` - Soft deletes a chat session

### Scheduled Functions
- `resetGuestMessageCounts` - Runs daily at midnight to reset guest user message counts

## Security

- All functions require authentication via Firebase Auth
- Guest users are limited to 5 messages per day
- Crisis detection triggers appropriate interventions
- User data is isolated by authentication

## Environment Variables

Required:
- `OPENAI_API_KEY` - Your OpenAI API key for GPT-4 access

## Testing

The functions include:
- Guest user message limiting
- Crisis keyword detection
- Conversation history management
- Proper error handling

## Notes

- Uses GPT-4o-mini model for cost-effective responses
- Implements therapeutic conversation guidelines
- Maintains conversation context (last 10 messages)
- Soft deletes preserve data integrity