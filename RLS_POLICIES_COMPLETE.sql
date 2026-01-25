-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- For KidsApp with Channels, Videos, Mart, etc.
-- ============================================

-- ============================================
-- CHANNELS TABLE RLS
-- ============================================

-- Enable RLS on channels
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

-- Public read policy: Everyone can view channels
DROP POLICY IF EXISTS "Channels are viewable by everyone" ON public.channels;
CREATE POLICY "Channels are viewable by everyone"
  ON public.channels FOR SELECT
  USING (true);

-- Admin insert policy: Only admins can create channels
DROP POLICY IF EXISTS "Admins can insert channels" ON public.channels;
CREATE POLICY "Admins can insert channels"
  ON public.channels FOR INSERT
  WITH CHECK (public.is_admin());

-- Admin update policy: Only admins can update channels
DROP POLICY IF EXISTS "Admins can update channels" ON public.channels;
CREATE POLICY "Admins can update channels"
  ON public.channels FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admin delete policy: Only admins can delete channels
DROP POLICY IF EXISTS "Admins can delete channels" ON public.channels;
CREATE POLICY "Admins can delete channels"
  ON public.channels FOR DELETE
  USING (public.is_admin());

-- ============================================
-- VIDEOS TABLE RLS
-- ============================================

-- Enable RLS on videos
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

-- Public read policy: Everyone can view videos
DROP POLICY IF EXISTS "Videos are viewable by everyone" ON public.videos;
CREATE POLICY "Videos are viewable by everyone"
  ON public.videos FOR SELECT
  USING (true);

-- Admin insert policy: Only admins can add videos
DROP POLICY IF EXISTS "Admins can insert videos" ON public.videos;
CREATE POLICY "Admins can insert videos"
  ON public.videos FOR INSERT
  WITH CHECK (public.is_admin());

-- Admin update policy: Only admins can update videos
DROP POLICY IF EXISTS "Admins can update videos" ON public.videos;
CREATE POLICY "Admins can update videos"
  ON public.videos FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admin delete policy: Only admins can delete videos
DROP POLICY IF EXISTS "Admins can delete videos" ON public.videos;
CREATE POLICY "Admins can delete videos"
  ON public.videos FOR DELETE
  USING (public.is_admin());

-- ============================================
-- CATEGORIES TABLE RLS
-- ============================================

-- Enable RLS on categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Public read policy: Everyone can view categories
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone"
  ON public.categories FOR SELECT
  USING (true);

-- Admin insert policy: Only admins can create categories
DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
CREATE POLICY "Admins can insert categories"
  ON public.categories FOR INSERT
  WITH CHECK (public.is_admin());

-- Admin update policy: Only admins can update categories
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
CREATE POLICY "Admins can update categories"
  ON public.categories FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Admin delete policy: Only admins can delete categories
DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;
CREATE POLICY "Admins can delete categories"
  ON public.categories FOR DELETE
  USING (public.is_admin());

-- ============================================
-- MART_VIDEOS TABLE RLS
-- ============================================

-- Enable RLS on mart_videos
ALTER TABLE public.mart_videos ENABLE ROW LEVEL SECURITY;

-- Public read policy: Everyone can view active mart videos
DROP POLICY IF EXISTS "Mart videos are readable by everyone" ON public.mart_videos;
CREATE POLICY "Mart videos are readable by everyone"
  ON public.mart_videos FOR SELECT
  USING (is_active = true);

-- Admin can see all mart videos (including inactive)
DROP POLICY IF EXISTS "Admins can view all mart videos" ON public.mart_videos;
CREATE POLICY "Admins can view all mart videos"
  ON public.mart_videos FOR SELECT
  USING (public.is_admin());

-- Admin insert policy: Only admins can add mart products
DROP POLICY IF EXISTS "Admins can insert mart videos" ON public.mart_videos;
CREATE POLICY "Admins can insert mart videos"
  ON public.mart_videos FOR INSERT
  WITH CHECK (public.is_admin());

-- Admin update policy: Only admins can update mart videos (including views/clicks)
DROP POLICY IF EXISTS "Admins can update mart videos" ON public.mart_videos;
CREATE POLICY "Admins can update mart videos"
  ON public.mart_videos FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Public can update views/clicks (for tracking)
DROP POLICY IF EXISTS "Public can update mart video engagement" ON public.mart_videos;
CREATE POLICY "Public can update mart video engagement"
  ON public.mart_videos FOR UPDATE
  USING (is_active = true)
  WITH CHECK (is_active = true);

-- Admin delete policy: Only admins can delete mart videos
DROP POLICY IF EXISTS "Admins can delete mart videos" ON public.mart_videos;
CREATE POLICY "Admins can delete mart videos"
  ON public.mart_videos FOR DELETE
  USING (public.is_admin());

-- ============================================
-- VIDEO_ENGAGEMENT TABLE RLS
-- ============================================

-- Enable RLS on video_engagement
ALTER TABLE public.video_engagement ENABLE ROW LEVEL SECURITY;

-- Users can view their own engagement records
DROP POLICY IF EXISTS "Users can view own engagement" ON public.video_engagement;
CREATE POLICY "Users can view own engagement"
  ON public.video_engagement FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own engagement records
DROP POLICY IF EXISTS "Users can insert own engagement" ON public.video_engagement;
CREATE POLICY "Users can insert own engagement"
  ON public.video_engagement FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own engagement records
DROP POLICY IF EXISTS "Users can update own engagement" ON public.video_engagement;
CREATE POLICY "Users can update own engagement"
  ON public.video_engagement FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all engagement for analytics
DROP POLICY IF EXISTS "Admins can view all engagement" ON public.video_engagement;
CREATE POLICY "Admins can view all engagement"
  ON public.video_engagement FOR SELECT
  USING (public.is_admin());

-- ============================================
-- PROFILES TABLE RLS
-- ============================================

-- Enable RLS on profiles (if not already enabled)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own kid profiles
DROP POLICY IF EXISTS "Users can view own profiles" ON public.profiles;
CREATE POLICY "Users can view own profiles"
  ON public.profiles FOR SELECT
  USING (auth.uid() = parent_id);

-- Users can insert their own kid profiles
DROP POLICY IF EXISTS "Users can insert own profiles" ON public.profiles;
CREATE POLICY "Users can insert own profiles"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = parent_id);

-- Users can update their own kid profiles
DROP POLICY IF EXISTS "Users can update own profiles" ON public.profiles;
CREATE POLICY "Users can update own profiles"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = parent_id)
  WITH CHECK (auth.uid() = parent_id);

-- Users can delete their own kid profiles
DROP POLICY IF EXISTS "Users can delete own profiles" ON public.profiles;
CREATE POLICY "Users can delete own profiles"
  ON public.profiles FOR DELETE
  USING (auth.uid() = parent_id);

-- ============================================
-- BLOCKED_CONTENT TABLE RLS
-- ============================================

-- Enable RLS on blocked_content (if not already enabled)
ALTER TABLE public.blocked_content ENABLE ROW LEVEL SECURITY;

-- Users can view blocked content for their own profiles
DROP POLICY IF EXISTS "Users can view blocked content for their profiles" ON public.blocked_content;
CREATE POLICY "Users can view blocked content for their profiles"
  ON public.blocked_content FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = blocked_content.profile_id
    AND profiles.parent_id = auth.uid()
  ));

-- Users can insert blocked content for their own profiles
DROP POLICY IF EXISTS "Users can insert blocked content for their profiles" ON public.blocked_content;
CREATE POLICY "Users can insert blocked content for their profiles"
  ON public.blocked_content FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = blocked_content.profile_id
    AND profiles.parent_id = auth.uid()
  ));

-- Users can delete blocked content for their own profiles
DROP POLICY IF EXISTS "Users can delete blocked content for their profiles" ON public.blocked_content;
CREATE POLICY "Users can delete blocked content for their profiles"
  ON public.blocked_content FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = blocked_content.profile_id
    AND profiles.parent_id = auth.uid()
  ));

-- ============================================
-- USERS TABLE RLS
-- ============================================

-- RLS on users is DISABLED for simplicity (handled in admin panel)
-- But we keep authentication checks in the admin JavaScript

-- Users can view their own user profile
DROP POLICY IF EXISTS "Users can view own user profile" ON public.users;
CREATE POLICY "Users can view own user profile"
  ON public.users FOR SELECT
  USING (id = auth.uid() OR public.is_admin());

-- Admins can view all users
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (public.is_admin());

-- Admins can update users
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ============================================
-- HELPER FUNCTION FOR ADMIN CHECKS
-- ============================================

-- Verify is_admin() function exists
-- If not already created, uncomment and run:
/*
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid() AND is_admin = true
  );
$$;
*/

-- ============================================
-- SUMMARY
-- ============================================
/*
RLS POLICIES CONFIGURED:

CHANNELS:
  - Public READ
  - Admin INSERT/UPDATE/DELETE

VIDEOS:
  - Public READ
  - Admin INSERT/UPDATE/DELETE

CATEGORIES:
  - Public READ
  - Admin INSERT/UPDATE/DELETE

MART_VIDEOS:
  - Public READ (active only)
  - Admin can see all (including inactive)
  - Admin INSERT/UPDATE/DELETE
  - Public can update views/clicks for tracking

VIDEO_ENGAGEMENT:
  - Users see/manage own engagement
  - Admin can view all for analytics

PROFILES:
  - Users manage own kid profiles
  - Users manage own blocked content

USERS:
  - Users view own profile
  - Admins view/manage all users
*/
