-- Crisis detection logging table for safety monitoring
CREATE TABLE IF NOT EXISTS crisis_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID,
    crisis_level INTEGER NOT NULL CHECK (crisis_level >= 0 AND crisis_level <= 10),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on crisis_logs
ALTER TABLE crisis_logs ENABLE ROW LEVEL SECURITY;

-- RLS policy: Users cannot see their own crisis logs (admin-only table for safety)
-- This prevents users from gaming the system or being triggered by their own crisis history
CREATE POLICY "Crisis logs are admin-only" ON crisis_logs
    FOR ALL USING (FALSE);

-- Create index for performance
CREATE INDEX idx_crisis_logs_user_timestamp ON crisis_logs(user_id, timestamp DESC);
CREATE INDEX idx_crisis_logs_level ON crisis_logs(crisis_level, timestamp DESC);

-- Grant access to service role for Edge Function
GRANT ALL ON crisis_logs TO service_role;