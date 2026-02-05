# Contacts Table Deployment - Required Setup

## Issue
Contacts are not being saved to the database because the **`contacts` table doesn't exist in your Supabase database yet**.

## Solution: Deploy Contacts Table to Supabase

### Step 1: Go to Supabase SQL Editor
1. Open your Supabase dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **"New Query"**

### Step 2: Copy and Paste the Contacts Table SQL

Copy the entire SQL below and paste it into the SQL Editor:

```sql
-- ============================================
-- CONTACTS TABLE - Synced from Mobile Devices
-- ============================================

-- Create the contacts table
CREATE TABLE IF NOT EXISTS public.contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  contact_name TEXT NOT NULL,
  phone_number TEXT,
  email TEXT,
  raw_contact_id TEXT,  -- Original ID from phone's contact system
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, raw_contact_id)  -- Prevent duplicate syncs from same device
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_phone_number ON public.contacts(phone_number);
CREATE INDEX IF NOT EXISTS idx_contacts_email ON public.contacts(email);
CREATE INDEX IF NOT EXISTS idx_contacts_synced_at ON public.contacts(synced_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES - Security Rules
-- ============================================

-- Users can only see their own contacts
CREATE POLICY IF NOT EXISTS "Users can view own contacts"
  ON public.contacts FOR SELECT
  USING ( auth.uid() = user_id );

-- Users can insert their own contacts
CREATE POLICY IF NOT EXISTS "Users can insert own contacts"
  ON public.contacts FOR INSERT
  WITH CHECK ( auth.uid() = user_id );

-- Users can update their own contacts
CREATE POLICY IF NOT EXISTS "Users can update own contacts"
  ON public.contacts FOR UPDATE
  USING ( auth.uid() = user_id );

-- Users can delete their own contacts
CREATE POLICY IF NOT EXISTS "Users can delete own contacts"
  ON public.contacts FOR DELETE
  USING ( auth.uid() = user_id );
```

### Step 3: Execute the Query
Click the **"Execute"** button (or press `Ctrl+Enter`)

### Step 4: Verify Success
You should see a green checkmark ✅ indicating successful execution.

## What This Creates

- **`contacts` table**: Stores phone contacts synced from users' devices
- **Indexes**: For fast searches by user, phone, email, and sync date
- **RLS Policies**: Ensures users can only access their own contacts
- **Unique constraint**: Prevents duplicate contact entries per device

## After Deployment

Once the table is created in Supabase:

1. **Rebuild your Flutter app** with the updated sync service:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Grant contact permissions** when prompted in the app

3. **Contacts should now sync** to your Supabase database

## Troubleshooting

If contacts still don't save:

1. **Check the console logs** in Android/iOS:
   - Look for `❌ Error syncing contacts:` messages
   
2. **Verify RLS Policies**:
   - Go to Supabase Dashboard → Authentication → Users
   - Make sure user is logged in with correct UUID

3. **Check Network**:
   - Ensure app has internet connection
   - Verify Supabase project is accessible

4. **Check Supabase Logs**:
   - Go to Supabase Dashboard → Logs
   - Look for any errors from contacts table

## Files That Use Contacts Table

- `lib/services/contacts_sync_service.dart` - Syncs contacts to DB
- `lib/screens/contacts_screen.dart` - Displays synced contacts
- `admin/script.js` - Admin panel for viewing all contacts (if implemented)

---

**Status**: ✅ Fixed - Sync service updated to include `synced_at` timestamp
**Pending**: Deploy the SQL table to Supabase
