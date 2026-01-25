-- ========================================================
-- QUICK FIX FOR INFINITE RECURSION ERROR
-- Run this in Supabase SQL Editor
-- ========================================================

-- Step 1: Remove the problematic RLS policy
DROP POLICY IF EXISTS "Users can view their own record" ON public.users;

-- Step 2: Disable RLS on users table
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Done! You should now be able to login to admin panel

-- ========================================================
-- VERIFICATION QUERY
-- Run this to confirm it worked:
-- ========================================================
SELECT table_name, row_security_enabled 
FROM information_schema.tables 
WHERE table_name = 'users' AND table_schema = 'public';

-- Should show: users | false (RLS disabled)
