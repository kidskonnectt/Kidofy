-- FCM (Firebase Cloud Messaging) Token Storage Table
-- This table stores FCM tokens for each user to enable push notifications

CREATE TABLE IF NOT EXISTS fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android', -- 'android', 'iOS', etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index for faster lookups by user_id
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);

-- Create index for efficient token lookups
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(fcm_token);

-- Enable Row Level Security
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only view their own FCM token
CREATE POLICY "Users can view own FCM token" ON fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can only update their own FCM token
CREATE POLICY "Users can update own FCM token" ON fcm_tokens
  FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Service role can insert/update tokens (for app backend)
CREATE POLICY "Service role can manage FCM tokens" ON fcm_tokens
  FOR ALL
  USING (NOT auth.is_authenticated() OR auth.jwt()->>'role' = 'service_role');

-- Comment on table
COMMENT ON TABLE fcm_tokens IS 'Stores Firebase Cloud Messaging tokens for push notifications';
COMMENT ON COLUMN fcm_tokens.user_id IS 'Reference to the user who owns this token';
COMMENT ON COLUMN fcm_tokens.fcm_token IS 'The FCM token to send push notifications to';
COMMENT ON COLUMN fcm_tokens.platform IS 'Platform (android, iOS, etc.)';
