# OmniAI Backend Architecture Guide

## Overview
This document outlines the backend architecture for OmniAI, a mental health therapy app with AI-powered features. The architecture prioritizes HIPAA compliance, user privacy, and therapeutic safety while integrating OpenAI for intelligent conversations.

## Current State Analysis

### SwiftUI App Architecture
- **Local-First Data Storage**: Journal entries persist locally using JSON files in Documents directory
- **Service-Based Architecture**: Modular managers (AuthenticationManager, JournalManager, PremiumManager)
- **Local-First Approach**: All data currently stored locally, ready for backend integration
- **Therapeutic Design**: Evidence-based color schemes, gentle UX patterns, crisis-aware interface

### Data Models
- **User**: Authentication, profile, preferences
- **JournalEntry**: Mood tracking, tags, content, timestamps
- **MoodType**: Emotional state categorization with visual indicators

## Proposed Fly.io Backend Architecture

### 1. Technology Stack

```yaml
Runtime: Node.js 20+ with TypeScript
Framework: Express.js / Fastify
Database: PostgreSQL 15+ (HIPAA-compliant)
Cache: Redis for session management
AI: OpenAI GPT-4 API
Monitoring: Sentry for error tracking
Logging: Winston with HIPAA audit trails
```

### 2. Project Structure

```
omniai-backend/
├── src/
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   ├── journal.controller.ts
│   │   ├── ai.controller.ts
│   │   └── crisis.controller.ts
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── journal.service.ts
│   │   ├── ai-therapy.service.ts
│   │   ├── encryption.service.ts
│   │   ├── mood-analysis.service.ts
│   │   └── crisis-detection.service.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── rate-limit.middleware.ts
│   │   ├── audit.middleware.ts
│   │   └── encryption.middleware.ts
│   ├── models/
│   │   ├── user.model.ts
│   │   ├── journal.model.ts
│   │   ├── conversation.model.ts
│   │   └── audit.model.ts
│   ├── utils/
│   │   ├── openai.client.ts
│   │   ├── encryption.utils.ts
│   │   └── validators.ts
│   └── config/
│       ├── database.config.ts
│       ├── openai.config.ts
│       └── security.config.ts
├── fly.toml
├── Dockerfile
└── package.json
```

### 3. API Endpoints

#### Authentication
```typescript
POST   /api/auth/register     // User registration with consent
POST   /api/auth/login        // JWT-based authentication
POST   /api/auth/refresh      // Token refresh
POST   /api/auth/logout       // Session termination
POST   /api/auth/verify-email // Email verification
DELETE /api/auth/account      // GDPR-compliant account deletion
```

#### Journal Management
```typescript
GET    /api/journal/entries          // Paginated journal list
POST   /api/journal/entries          // Create new entry
PUT    /api/journal/entries/:id      // Update entry
DELETE /api/journal/entries/:id      // Delete entry
POST   /api/journal/sync             // Sync local entries
GET    /api/journal/mood-stats       // Mood analytics
```

#### AI Therapy Services
```typescript
POST   /api/ai/chat                  // Therapeutic conversation
POST   /api/ai/analyze-mood          // Mood pattern analysis
POST   /api/ai/generate-insights     // Journal insights
POST   /api/ai/suggest-exercises     // Therapeutic exercises
GET    /api/ai/conversation/:id      // Retrieve past conversation
```

#### Crisis Management
```typescript
POST   /api/crisis/assess            // Evaluate crisis level
POST   /api/crisis/resources         // Get emergency resources
POST   /api/crisis/escalate          // Trigger human intervention
GET    /api/crisis/hotlines          // Location-based hotlines
```

### 4. Database Schema

```sql
-- Users table with HIPAA compliance fields
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    email_verified BOOLEAN DEFAULT false,
    auth_provider VARCHAR(50),
    consent_timestamp TIMESTAMP,
    consent_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Journal entries with encryption support
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title_encrypted TEXT NOT NULL,
    content_encrypted TEXT NOT NULL,
    mood VARCHAR(50),
    tags JSONB,
    is_favorite BOOLEAN DEFAULT false,
    encryption_key_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- AI conversations for context
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    messages JSONB NOT NULL,
    mood_context VARCHAR(50),
    crisis_level INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- HIPAA audit log
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    action VARCHAR(100),
    resource_type VARCHAR(50),
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT NOW()
);
```

### 5. Security Implementation

#### Data Encryption
```typescript
// End-to-end encryption for PHI data
class EncryptionService {
    // AES-256-GCM encryption for data at rest
    encryptPHI(data: string, userId: string): EncryptedData
    
    // Client-side encryption keys
    generateUserKeyPair(): KeyPair
    
    // Key rotation mechanism
    rotateEncryptionKeys(): void
}
```

#### Authentication & Authorization
```typescript
// JWT with refresh tokens
interface AuthToken {
    userId: string;
    sessionId: string;
    permissions: string[];
    expiresAt: Date;
}

// Role-based access control
enum UserRole {
    USER = 'user',
    PREMIUM = 'premium',
    CRISIS_RESPONDER = 'crisis_responder',
    ADMIN = 'admin'
}
```

#### Rate Limiting
```typescript
// OpenAI API rate limiting
const aiRateLimiter = {
    maxRequests: 10,
    windowMs: 60000, // 1 minute
    premiumMaxRequests: 30
}

// Crisis detection bypass
const crisisBypassRateLimit = true;
```

### 6. OpenAI Integration

#### Therapeutic Conversation System
```typescript
class AITherapyService {
    private systemPrompt = `
        You are a supportive mental health companion. You are NOT a replacement 
        for professional therapy. Your role is to:
        - Provide emotional support and validation
        - Teach coping strategies and mindfulness exercises
        - Encourage professional help when appropriate
        - Detect crisis situations and escalate immediately
        
        NEVER:
        - Diagnose mental health conditions
        - Prescribe medications
        - Replace professional therapy
        - Minimize serious concerns
    `;
    
    async createTherapeuticResponse(
        userMessage: string,
        moodContext: MoodType,
        conversationHistory: Message[]
    ): Promise<TherapeuticResponse> {
        // Crisis detection first
        const crisisLevel = await this.assessCrisisLevel(userMessage);
        
        if (crisisLevel > CRISIS_THRESHOLD) {
            return this.handleCrisisResponse(userMessage);
        }
        
        // Generate therapeutic response
        const response = await openai.chat.completions.create({
            model: "gpt-4",
            messages: [
                { role: "system", content: this.systemPrompt },
                ...conversationHistory,
                { role: "user", content: userMessage }
            ],
            temperature: 0.7,
            max_tokens: 500
        });
        
        return {
            message: response.choices[0].message.content,
            suggestedExercises: await this.getSuggestedExercises(moodContext),
            crisisResources: crisisLevel > 0 ? this.getCrisisResources() : null
        };
    }
}
```

#### Crisis Detection System
```typescript
class CrisisDetectionService {
    private crisisKeywords = [
        'suicide', 'kill myself', 'end it all', 'not worth living',
        'self-harm', 'cutting', 'overdose', 'no point'
    ];
    
    async assessCrisisLevel(message: string): Promise<number> {
        // Keyword detection
        const hasKeywords = this.crisisKeywords.some(keyword => 
            message.toLowerCase().includes(keyword)
        );
        
        // Sentiment analysis via AI
        const sentiment = await this.analyzeSentiment(message);
        
        // Calculate crisis level (0-10)
        let level = 0;
        if (hasKeywords) level += 5;
        if (sentiment.score < -0.8) level += 3;
        if (sentiment.despair > 0.7) level += 2;
        
        return Math.min(level, 10);
    }
    
    async handleCrisisIntervention(userId: string, message: string): Promise<CrisisResponse> {
        // Log for audit
        await this.auditLog.crisis(userId, message);
        
        // Get immediate resources
        const resources = await this.getLocalCrisisResources(userId);
        
        // Notify crisis team if configured
        if (process.env.CRISIS_TEAM_WEBHOOK) {
            await this.notifyCrisisTeam(userId, message);
        }
        
        return {
            message: "I'm concerned about you. Your safety is important...",
            resources: resources,
            hotlines: this.getNationalHotlines(),
            escalated: true
        };
    }
}
```

### 7. HIPAA Compliance Requirements

#### Technical Safeguards
- **Access Control**: Role-based permissions, session timeouts
- **Audit Controls**: Comprehensive logging of all PHI access
- **Integrity Controls**: Data validation, checksums
- **Transmission Security**: TLS 1.3+ for all connections

#### Administrative Safeguards
- **Business Associate Agreement**: Required with OpenAI
- **Access Management**: User provisioning/de-provisioning
- **Training**: Security awareness for all staff
- **Incident Response**: Breach notification procedures

#### Physical Safeguards (Fly.io handles)
- **Data Center Security**: SOC 2 certified facilities
- **Device Controls**: Encrypted storage
- **Backup**: Automated encrypted backups

### 8. Fly.io Deployment Configuration

#### fly.toml
```toml
app = "omniai-backend"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  NODE_ENV = "production"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

[[services]]
  protocol = "tcp"
  internal_port = 8080
  
  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
    
  [[services.ports]]
    port = 80
    handlers = ["http"]
    force_https = true

[checks]
  [checks.health]
    port = 8080
    type = "http"
    interval = "10s"
    timeout = "2s"
    path = "/health"

[[statics]]
  guest_path = "/app/public"
  url_prefix = "/static"
```

#### Environment Variables
```bash
# Database
DATABASE_URL=postgres://user:pass@host:5432/omniai
REDIS_URL=redis://host:6379

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_ORG_ID=org-...
OPENAI_MODEL=gpt-4

# Security
JWT_SECRET=<generate-strong-secret>
ENCRYPTION_KEY=<generate-256-bit-key>
REFRESH_TOKEN_SECRET=<generate-strong-secret>

# Crisis Management
CRISIS_TEAM_WEBHOOK=https://...
CRISIS_THRESHOLD=7

# Monitoring
SENTRY_DSN=https://...
LOG_LEVEL=info

# HIPAA Compliance
AUDIT_ENABLED=true
PHI_ENCRYPTION_REQUIRED=true
SESSION_TIMEOUT_MINUTES=15
```

### 9. SwiftUI Integration Updates

#### Network Service Layer
```swift
class APIService {
    static let shared = APIService()
    private let baseURL = "https://omniai-backend.fly.dev/api"
    
    func syncJournalEntries() async throws {
        // Sync local entries with backend
    }
    
    func startTherapyChat(mood: MoodType) async throws -> ConversationSession {
        // Initialize AI therapy session
    }
}
```

#### Updated AuthenticationManager
```swift
extension AuthenticationManager {
    func authenticateWithBackend(email: String, password: String) async throws {
        // Replace local auth with API calls
        let response = try await APIService.shared.login(email, password)
        self.currentUser = response.user
        self.storeTokens(response.accessToken, response.refreshToken)
    }
}
```

### 10. Testing Strategy

#### Unit Tests
- Service layer business logic
- Encryption/decryption functions
- Crisis detection algorithms
- JWT token generation/validation

#### Integration Tests
- API endpoint functionality
- Database operations
- OpenAI API interactions
- Rate limiting behavior

#### Compliance Tests
- HIPAA audit logging
- Data encryption verification
- Access control validation
- Session timeout enforcement

#### Load Tests
- Concurrent user sessions
- OpenAI API rate limits
- Database connection pooling
- Crisis response times

### 11. Monitoring & Observability

#### Metrics to Track
- API response times
- OpenAI API usage/costs
- Crisis detection triggers
- User engagement patterns
- Error rates by endpoint

#### Alerts
- High crisis detection rate
- OpenAI API failures
- Database connection issues
- Unusual access patterns
- Failed authentication attempts

### 12. Cost Optimization

#### OpenAI API
- Cache common responses
- Implement prompt engineering for efficiency
- Use GPT-3.5 for non-critical features
- Batch similar requests

#### Database
- Index optimization for common queries
- Connection pooling
- Read replicas for analytics
- Automated cleanup of old audit logs

#### Fly.io
- Auto-scaling based on load
- Regional deployment strategy
- Efficient Docker images
- Static asset CDN

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Set up Fly.io app and PostgreSQL
- Implement basic authentication
- Create journal sync endpoints
- Set up HIPAA audit logging

### Phase 2: AI Integration (Week 3-4)
- Integrate OpenAI API
- Implement therapeutic chat
- Add mood analysis
- Basic crisis detection

### Phase 3: Security & Compliance (Week 5-6)
- End-to-end encryption
- Complete HIPAA compliance
- Crisis management system
- Security testing

### Phase 4: SwiftUI Integration (Week 7-8)
- Update app networking layer
- Implement data sync
- Add AI chat interface
- Testing and optimization

## Legal Considerations

### Required Disclosures
- AI is not a replacement for therapy
- Data collection and usage policies
- Crisis intervention procedures
- Third-party service usage (OpenAI)

### User Consent Requirements
- Explicit consent for AI interactions
- PHI data processing agreement
- Right to data deletion (GDPR)
- Marketing communication opt-in

### Liability Limitations
- No medical advice disclaimer
- Crisis response limitations
- Data breach notifications
- Service availability SLA

## Conclusion

This architecture provides a robust, HIPAA-compliant backend for OmniAI that prioritizes user safety and privacy while leveraging AI for therapeutic support. The modular design allows for incremental implementation and scaling as the user base grows.

Key success factors:
- Strong encryption and security practices
- Reliable crisis detection and intervention
- Seamless SwiftUI app integration
- Cost-effective OpenAI usage
- Comprehensive compliance measures

The backend serves as a supportive infrastructure that enhances the therapeutic value of the OmniAI app while maintaining the highest standards of privacy and safety for vulnerable users.