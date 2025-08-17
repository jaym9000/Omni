-- Supabase Database Schema for OmniAI Mental Health App
-- Run this SQL in your Supabase dashboard > SQL Editor

-- 1. Create users table for profile data
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    companion_name TEXT DEFAULT 'Omni',
    companion_personality TEXT DEFAULT 'supportive',
    email_verified BOOLEAN DEFAULT FALSE,
    auth_provider TEXT DEFAULT 'email',
    biometric_auth_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create chat_sessions table
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'New Chat',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create chat_messages table (with real-time support)
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create mood_entries table
CREATE TABLE mood_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mood_type TEXT NOT NULL, -- 'happy', 'sad', 'anxious', 'calm', 'overwhelmed'
    emoji TEXT NOT NULL,
    color TEXT NOT NULL,
    label TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create journal_entries table
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    entry_type TEXT NOT NULL, -- 'freeForm', 'tagged', 'themed', 'dailyPrompt'
    mood_type TEXT,
    mood_emoji TEXT,
    mood_color TEXT,
    mood_label TEXT,
    tags TEXT[], -- Array of tags
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create triggers for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_chat_sessions_updated_at BEFORE UPDATE ON chat_sessions
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth_user_id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth_user_id = auth.uid());

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth_user_id = auth.uid());

-- Create RLS policies for chat_sessions table
CREATE POLICY "Users can view own chat sessions" ON chat_sessions
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create own chat sessions" ON chat_sessions
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own chat sessions" ON chat_sessions
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own chat sessions" ON chat_sessions
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- Create RLS policies for chat_messages table
CREATE POLICY "Users can view messages from own sessions" ON chat_messages
    FOR SELECT USING (session_id IN (
        SELECT cs.id FROM chat_sessions cs 
        JOIN users u ON cs.user_id = u.id 
        WHERE u.auth_user_id = auth.uid()
    ));

CREATE POLICY "Users can create messages in own sessions" ON chat_messages
    FOR INSERT WITH CHECK (session_id IN (
        SELECT cs.id FROM chat_sessions cs 
        JOIN users u ON cs.user_id = u.id 
        WHERE u.auth_user_id = auth.uid()
    ));

-- Create RLS policies for mood_entries table
CREATE POLICY "Users can view own mood entries" ON mood_entries
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create own mood entries" ON mood_entries
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own mood entries" ON mood_entries
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own mood entries" ON mood_entries
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- Create RLS policies for journal_entries table
CREATE POLICY "Users can view own journal entries" ON journal_entries
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can create own journal entries" ON journal_entries
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can update own journal entries" ON journal_entries
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

CREATE POLICY "Users can delete own journal entries" ON journal_entries
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid()));

-- Enable real-time for chat_messages (for live chat updates)
-- Run this separately in Supabase dashboard > Database > Replication
-- ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Create indexes for better performance
CREATE INDEX idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_mood_entries_user_id ON mood_entries(user_id);
CREATE INDEX idx_mood_entries_created_at ON mood_entries(created_at);
CREATE INDEX idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX idx_journal_entries_created_at ON journal_entries(created_at);