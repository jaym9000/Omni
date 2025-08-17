import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Crisis detection keywords for mental health safety
const CRISIS_KEYWORDS = [
  'suicide', 'kill myself', 'end it all', 'not worth living',
  'self-harm', 'cutting', 'overdose', 'no point', 'want to die',
  'better off dead', 'no reason to live', 'give up'
]

// Therapeutic system prompt for mental health support
const SYSTEM_PROMPT = `You are Omni, a compassionate and supportive mental health companion. Your role is to provide emotional support, validation, and evidence-based coping strategies.

IMPORTANT GUIDELINES:
1. You are NOT a replacement for professional therapy or medical advice
2. Always validate emotions and show empathy
3. Suggest evidence-based coping strategies when appropriate
4. Encourage professional help for serious concerns
5. Use gentle, non-judgmental language
6. Focus on the present moment and practical support
7. Never diagnose conditions or prescribe medications

THERAPEUTIC APPROACH:
- Use active listening and reflection techniques
- Ask open-ended questions to encourage expression
- Validate feelings before offering suggestions
- Provide grounding techniques for anxiety
- Suggest mindfulness and breathing exercises when appropriate
- Maintain a warm, supportive tone throughout

SAFETY PROTOCOL:
If someone expresses thoughts of self-harm or suicide:
1. Express immediate concern and care
2. Provide crisis resources
3. Strongly encourage professional help
4. Do not minimize their feelings
5. Stay supportive and non-judgmental`

interface ChatRequest {
  message: string
  sessionId: string
  mood?: string
  conversationHistory?: Array<{
    role: 'user' | 'assistant'
    content: string
  }>
}

interface CrisisResponse {
  detected: boolean
  level: number // 0-10 scale
  keywords: string[]
  resources: {
    hotlines: Array<{
      name: string
      number: string
      hours: string
    }>
    textLines: Array<{
      name: string
      number: string
      info: string
    }>
    websites: string[]
  }
}

// Crisis detection function
function detectCrisis(message: string): CrisisResponse {
  const lowerMessage = message.toLowerCase()
  const detectedKeywords = CRISIS_KEYWORDS.filter(keyword => 
    lowerMessage.includes(keyword)
  )
  
  const crisisDetected = detectedKeywords.length > 0
  const crisisLevel = Math.min(detectedKeywords.length * 3, 10)
  
  return {
    detected: crisisDetected,
    level: crisisLevel,
    keywords: detectedKeywords,
    resources: {
      hotlines: [
        {
          name: "National Suicide Prevention Lifeline",
          number: "988",
          hours: "24/7"
        },
        {
          name: "Crisis Text Line",
          number: "Text HOME to 741741",
          hours: "24/7"
        }
      ],
      textLines: [
        {
          name: "Crisis Text Line",
          number: "741741",
          info: "Text HOME to connect"
        }
      ],
      websites: [
        "https://988lifeline.org",
        "https://www.crisistextline.org",
        "https://www.samhsa.gov/find-help"
      ]
    }
  }
}

// Generate contextual prompt based on mood
function getMoodContext(mood?: string): string {
  const moodPrompts: Record<string, string> = {
    'anxious': 'The user is feeling anxious. Focus on grounding techniques, breathing exercises, and validation of their anxiety.',
    'sad': 'The user is feeling sad. Provide emotional validation, gentle support, and avoid toxic positivity.',
    'stressed': 'The user is feeling stressed. Help them identify stressors and suggest practical stress management techniques.',
    'overwhelmed': 'The user is feeling overwhelmed. Help them break down their concerns and focus on one thing at a time.',
    'calm': 'The user is feeling calm. This is a good time for reflection and building coping strategies.',
    'happy': 'The user is feeling happy. Celebrate with them and help them maintain this positive state.'
  }
  
  return mood && moodPrompts[mood.toLowerCase()] 
    ? `\n\nCONTEXT: ${moodPrompts[mood.toLowerCase()]}` 
    : ''
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify authentication
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role for auth verification
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      }
    })

    // Verify JWT and get user
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { message, sessionId, mood, conversationHistory = [] }: ChatRequest = await req.json()

    if (!message || !sessionId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check for crisis situation
    const crisisCheck = detectCrisis(message)
    
    // If high crisis level, return immediate crisis response
    if (crisisCheck.level >= 7) {
      // Log crisis detection for safety monitoring (with privacy protection)
      await supabase
        .from('crisis_logs')
        .insert({
          user_id: user.id,
          session_id: sessionId,
          crisis_level: crisisCheck.level,
          timestamp: new Date().toISOString()
        })

      const crisisMessage = `I'm genuinely concerned about what you're sharing. Your life has value, and there are people who want to help.

Please reach out to a crisis counselor right now:
• Call or text 988 (Suicide & Crisis Lifeline) - available 24/7
• Text HOME to 741741 (Crisis Text Line) - available 24/7

These services are free, confidential, and staffed by trained counselors who can provide immediate support.

If you're in immediate danger, please call 911 or go to your nearest emergency room.

You don't have to go through this alone. Professional help is available, and things can get better with the right support.`

      return new Response(
        JSON.stringify({
          content: crisisMessage,
          crisisDetected: true,
          crisisResources: crisisCheck.resources,
          requiresEscalation: true
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get OpenAI API key from environment
    const openAIApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openAIApiKey) {
      console.error('OpenAI API key not configured')
      return new Response(
        JSON.stringify({ error: 'AI service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build conversation messages for OpenAI
    const messages = [
      { 
        role: 'system', 
        content: SYSTEM_PROMPT + getMoodContext(mood)
      },
      ...conversationHistory.slice(-10), // Keep last 10 messages for context
      { role: 'user', content: message }
    ]

    // Call OpenAI API
    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openAIApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages,
        temperature: 0.7,
        max_tokens: 500,
        presence_penalty: 0.1,
        frequency_penalty: 0.1
      })
    })

    if (!openAIResponse.ok) {
      const error = await openAIResponse.text()
      console.error('OpenAI API error:', error)
      
      // Fallback to supportive response if OpenAI fails
      const fallbackMessage = "I hear you and I'm here to support you. It sounds like you're going through something challenging right now. Would you like to talk more about what's on your mind? Remember, your feelings are valid and it's okay to take things one step at a time."
      
      return new Response(
        JSON.stringify({
          content: fallbackMessage,
          isFallback: true
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const aiData = await openAIResponse.json()
    const aiMessage = aiData.choices[0].message.content

    // Store conversation in database for continuity
    await supabase
      .from('chat_messages')
      .insert([
        {
          session_id: sessionId,
          user_id: user.id,
          content: message,
          is_user: true,
          created_at: new Date().toISOString()
        },
        {
          session_id: sessionId,
          user_id: user.id,
          content: aiMessage,
          is_user: false,
          created_at: new Date().toISOString()
        }
      ])

    // Return AI response with any low-level crisis resources if needed
    return new Response(
      JSON.stringify({
        content: aiMessage,
        crisisDetected: crisisCheck.detected && crisisCheck.level < 7,
        crisisResources: crisisCheck.detected ? crisisCheck.resources : null
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'An error occurred', 
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})