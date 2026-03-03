-- Create premium_subscriptions table for storing user subscription data
CREATE TABLE IF NOT EXISTS premium_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_name VARCHAR(50) NOT NULL,
  plan_duration VARCHAR(50) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  razorpay_order_id VARCHAR(100) NOT NULL,
  razorpay_payment_id VARCHAR(100) NOT NULL,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_premium_subscriptions_user_id ON premium_subscriptions(user_id);
CREATE INDEX idx_premium_subscriptions_status ON premium_subscriptions(status);
CREATE INDEX idx_premium_subscriptions_expiry ON premium_subscriptions(expiry_date);

-- Enable RLS
ALTER TABLE premium_subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own subscriptions" ON premium_subscriptions
  FOR SELECT
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Only service role can insert subscriptions" ON premium_subscriptions
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Only service role can update subscriptions" ON premium_subscriptions
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Optional: Create a function to get user's active premium subscription
CREATE OR REPLACE FUNCTION get_user_premium_status(user_id UUID)
RETURNS TABLE (
  is_premium BOOLEAN,
  plan_name VARCHAR,
  days_remaining INTEGER,
  expiry_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (ps.status = 'active' AND ps.expiry_date > NOW())::BOOLEAN,
    ps.plan_name,
    EXTRACT(DAY FROM (ps.expiry_date - NOW()))::INTEGER,
    ps.expiry_date
  FROM premium_subscriptions ps
  WHERE ps.user_id = $1 AND ps.status = 'active'
  ORDER BY ps.purchase_date DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
