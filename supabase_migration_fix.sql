-- Migration to fix email sign-up and guest user support in OmniAI
-- Run this in Supabase Dashboard > SQL Editor after the initial setup

-- 1. Add missing columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_guest BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS guest_conversation_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS max_guest_conversations INTEGER DEFAULT 3;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_reminder_time TIMESTAMPTZ;

-- 2. Drop existing RLS policies that are too restrictive
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;

-- 3. Create more flexible RLS policies for users table

-- Allow users to view their own profile (including anonymous users)
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (
        auth_user_id = auth.uid() OR
        (auth_user_id IS NOT NULL AND auth.uid() IS NOT NULL AND auth_user_id = auth.uid())
    );

-- Allow users to insert their own profile (including during sign-up)
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (
        -- Allow insert if auth_user_id matches current user
        auth_user_id = auth.uid() OR
        -- Allow insert during sign-up process when auth.uid() exists but record doesn't
        (auth.uid() IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM users WHERE auth_user_id = auth.uid()
        ))
    );

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (
        auth_user_id = auth.uid()
    )
    WITH CHECK (
        auth_user_id = auth.uid()
    );

-- Allow users to upsert (insert or update) their own profile
CREATE POLICY "Users can upsert own profile" ON users
    FOR ALL USING (
        auth_user_id = auth.uid() OR
        (auth.uid() IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM users WHERE auth_user_id = auth.uid()
        ))
    );

-- 4. Create service role policy for admin operations
CREATE POLICY "Service role has full access" ON users
    FOR ALL USING (
        auth.role() = 'service_role'
    );

-- 5. Create function to safely upsert user profiles
CREATE OR REPLACE FUNCTION upsert_user_profile(
    p_auth_user_id UUID,
    p_email TEXT,
    p_display_name TEXT,
    p_email_verified BOOLEAN DEFAULT FALSE,
    p_auth_provider TEXT DEFAULT 'email',
    p_is_guest BOOLEAN DEFAULT FALSE
)
RETURNS users AS $$
DECLARE
    v_user users;
BEGIN
    INSERT INTO users (
        auth_user_id,
        email,
        display_name,
        email_verified,
        auth_provider,
        is_guest,
        created_at,
        updated_at
    ) VALUES (
        p_auth_user_id,
        p_email,
        p_display_name,
        p_email_verified,
        p_auth_provider,
        p_is_guest,
        NOW(),
        NOW()
    )
    ON CONFLICT (auth_user_id) DO UPDATE
    SET
        email = EXCLUDED.email,
        display_name = EXCLUDED.display_name,
        email_verified = EXCLUDED.email_verified,
        auth_provider = EXCLUDED.auth_provider,
        is_guest = EXCLUDED.is_guest,
        updated_at = NOW()
    RETURNING * INTO v_user;
    
    RETURN v_user;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated and anon users
GRANT EXECUTE ON FUNCTION upsert_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_user_profile TO anon;

-- 6. Update chat_messages table to handle user_id for Edge Function
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id);

-- 7. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_is_guest ON users(is_guest);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at);

-- 8. Create or replace the crisis_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS crisis_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    session_id UUID,
    crisis_level INTEGER NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on crisis_logs
ALTER TABLE crisis_logs ENABLE ROW LEVEL SECURITY;

-- Only service role can access crisis logs
CREATE POLICY "Service role can manage crisis logs" ON crisis_logs
    FOR ALL USING (auth.role() = 'service_role');

-- 9. Add a helper function to get user by auth_user_id
CREATE OR REPLACE FUNCTION get_user_by_auth_id(p_auth_user_id UUID)
RETURNS users AS $$
    SELECT * FROM users WHERE auth_user_id = p_auth_user_id LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_user_by_auth_id TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_by_auth_id TO anon;

-- 10. Fix for anonymous user creation
-- Allow anonymous users to create their profile
CREATE POLICY "Anonymous users can create profile" ON users
    FOR INSERT WITH CHECK (
        auth.role() = 'anon' AND is_guest = true
    );

-- 11. Print confirmation
DO $$
BEGIN
    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE 'Users table now supports guest users and has proper RLS policies.';
    RAISE NOTICE 'Email sign-up should now work without RLS violations.';
END $$;