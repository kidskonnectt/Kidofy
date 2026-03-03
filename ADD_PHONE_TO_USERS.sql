-- =====================================================
-- ADD PHONE_NUMBER COLUMN TO USERS TABLE
-- =====================================================

-- Step 1: Add phone_number column to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(10);

-- Step 2: Add index for faster queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_users_phone_number ON public.users(phone_number);

-- Step 3: Verify the column was added
-- SELECT id, email, phone_number, created_at FROM public.users LIMIT 1;

-- =====================================================
-- NOTES:
-- =====================================================
-- - phone_number stored as VARCHAR(10) since it's only digits without +91
-- - Max 10 digits for Indian phone numbers
-- - Nullable by default (existing users won't have phone number)
-- - New users will have phone_number saved during signup
