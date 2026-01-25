-- ========================================================
-- QUICK FIX: Profiles insert/select failing after Google login
-- Also fixes a common typo: crated_at -> created_at
-- Run this in Supabase SQL Editor
-- ========================================================

DO $$
DECLARE
  parent_col text;
  has_crated_at boolean;
  has_created_at boolean;
BEGIN
  -- Detect the parent/user column name
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'parent_id'
  ) THEN
    parent_col := 'parent_id';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_id'
  ) THEN
    parent_col := 'user_id';
  ELSE
    RAISE EXCEPTION 'profiles table missing parent_id/user_id column';
  END IF;

  -- Fix crated_at typo if present
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'crated_at'
  ) INTO has_crated_at;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'created_at'
  ) INTO has_created_at;

  IF has_crated_at AND NOT has_created_at THEN
    EXECUTE 'ALTER TABLE public.profiles RENAME COLUMN crated_at TO created_at';
  END IF;

  -- Ensure RLS is enabled
  EXECUTE 'ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY';

  -- Drop and recreate policies using the detected parent column
  EXECUTE 'DROP POLICY IF EXISTS "Users can view own profiles" ON public.profiles';
  EXECUTE format(
    'CREATE POLICY "Users can view own profiles" ON public.profiles FOR SELECT USING (auth.uid() = %I)',
    parent_col
  );

  EXECUTE 'DROP POLICY IF EXISTS "Users can insert own profiles" ON public.profiles';
  EXECUTE format(
    'CREATE POLICY "Users can insert own profiles" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = %I)',
    parent_col
  );

  EXECUTE 'DROP POLICY IF EXISTS "Users can update own profiles" ON public.profiles';
  EXECUTE format(
    'CREATE POLICY "Users can update own profiles" ON public.profiles FOR UPDATE USING (auth.uid() = %I) WITH CHECK (auth.uid() = %I)',
    parent_col,
    parent_col
  );

  EXECUTE 'DROP POLICY IF EXISTS "Users can delete own profiles" ON public.profiles';
  EXECUTE format(
    'CREATE POLICY "Users can delete own profiles" ON public.profiles FOR DELETE USING (auth.uid() = %I)',
    parent_col
  );

  -- Blocked content policies (optional, but usually needed)
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'blocked_content'
  ) THEN
    EXECUTE 'ALTER TABLE public.blocked_content ENABLE ROW LEVEL SECURITY';

    EXECUTE 'DROP POLICY IF EXISTS "Users can view blocked content for their profiles" ON public.blocked_content';
    EXECUTE format(
      'CREATE POLICY "Users can view blocked content for their profiles" ON public.blocked_content FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = blocked_content.profile_id AND p.%I = auth.uid()))',
      parent_col
    );

    EXECUTE 'DROP POLICY IF EXISTS "Users can insert blocked content for their profiles" ON public.blocked_content';
    EXECUTE format(
      'CREATE POLICY "Users can insert blocked content for their profiles" ON public.blocked_content FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = blocked_content.profile_id AND p.%I = auth.uid()))',
      parent_col
    );

    EXECUTE 'DROP POLICY IF EXISTS "Users can delete blocked content for their profiles" ON public.blocked_content';
    EXECUTE format(
      'CREATE POLICY "Users can delete blocked content for their profiles" ON public.blocked_content FOR DELETE USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = blocked_content.profile_id AND p.%I = auth.uid()))',
      parent_col
    );
  END IF;

END $$;

-- Verification (should return your own profiles after login)
-- SELECT * FROM public.profiles;
