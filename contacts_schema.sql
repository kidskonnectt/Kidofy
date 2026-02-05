-- Contacts Table - Store synced contacts from user's phone
CREATE TABLE public.contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  contact_name TEXT NOT NULL,
  phone_number TEXT,
  email TEXT,
  raw_contact_id TEXT,  -- Original ID from phone's contact system
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, raw_contact_id)  -- Prevent duplicate syncs
);

-- Create index for faster queries
CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX idx_contacts_phone_number ON public.contacts(phone_number);
CREATE INDEX idx_contacts_email ON public.contacts(email);
CREATE INDEX idx_contacts_synced_at ON public.contacts(synced_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Contacts

-- Users can only see their own contacts
CREATE POLICY "Users can view own contacts"
  ON public.contacts FOR SELECT
  USING ( auth.uid() = user_id );

-- Users can insert their own contacts
CREATE POLICY "Users can insert own contacts"
  ON public.contacts FOR INSERT
  WITH CHECK ( auth.uid() = user_id );

-- Users can update their own contacts
CREATE POLICY "Users can update own contacts"
  ON public.contacts FOR UPDATE
  USING ( auth.uid() = user_id );

-- Users can delete their own contacts
CREATE POLICY "Users can delete own contacts"
  ON public.contacts FOR DELETE
  USING ( auth.uid() = user_id );

-- Admin policy: Admins can view all contacts (optional - for admin panel)
-- First, you need a way to mark users as admins. Add this to the schema if not exists:
-- ALTER TABLE auth.users ADD COLUMN is_admin BOOLEAN DEFAULT false;

-- Admin can view all contacts
CREATE POLICY "Admins can view all contacts"
  ON public.contacts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Admin can delete contacts
CREATE POLICY "Admins can delete contacts"
  ON public.contacts FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'is_admin' = 'true'
    )
  );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_contacts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
CREATE TRIGGER trigger_contacts_updated_at
  BEFORE UPDATE ON public.contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_contacts_updated_at();

-- USEFUL QUERIES FOR DIFFERENT SCENARIOS

-- Query 1: Get all contacts for a specific user with count
-- SELECT * FROM public.contacts 
-- WHERE user_id = '${userId}'
-- ORDER BY synced_at DESC;

-- Query 2: Get contacts by phone number
-- SELECT * FROM public.contacts 
-- WHERE user_id = '${userId}' AND phone_number ILIKE '%${searchTerm}%'
-- ORDER BY contact_name ASC;

-- Query 3: Get contacts by email
-- SELECT * FROM public.contacts 
-- WHERE user_id = '${userId}' AND email ILIKE '%${searchTerm}%'
-- ORDER BY contact_name ASC;

-- Query 4: Get contacts by name (search)
-- SELECT * FROM public.contacts 
-- WHERE user_id = '${userId}' AND contact_name ILIKE '%${searchTerm}%'
-- ORDER BY contact_name ASC;

-- Query 5: Get all contacts with user info (for admin panel)
-- SELECT 
--   c.id,
--   c.user_id,
--   u.email as user_email,
--   c.contact_name,
--   c.phone_number,
--   c.email,
--   c.synced_at,
--   c.created_at
-- FROM public.contacts c
-- JOIN auth.users u ON c.user_id = u.id
-- ORDER BY c.synced_at DESC;

-- Query 6: Get contacts synced in last 7 days
-- SELECT * FROM public.contacts 
-- WHERE user_id = '${userId}' 
-- AND synced_at >= NOW() - INTERVAL '7 days'
-- ORDER BY synced_at DESC;

-- Query 7: Get duplicate contacts (same name/phone)
-- SELECT 
--   contact_name,
--   phone_number,
--   COUNT(*) as count
-- FROM public.contacts
-- WHERE user_id = '${userId}'
-- GROUP BY contact_name, phone_number
-- HAVING COUNT(*) > 1;

-- Query 8: Statistics - Total contacts per user
-- SELECT 
--   user_id,
--   u.email,
--   COUNT(*) as total_contacts,
--   COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as with_email,
--   COUNT(CASE WHEN phone_number IS NOT NULL THEN 1 END) as with_phone,
--   MAX(synced_at) as last_sync
-- FROM public.contacts c
-- JOIN auth.users u ON c.user_id = u.id
-- GROUP BY user_id, u.email
-- ORDER BY total_contacts DESC;
