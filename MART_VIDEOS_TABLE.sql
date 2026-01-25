-- Mart Videos Table (Product Ads with Commission Tracking)
-- User uploads VIDEO + LINK, we track views and clicks for commission

CREATE TABLE IF NOT EXISTS mart_videos (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  video_url TEXT NOT NULL,  -- Bunny CDN video path (9:16 aspect ratio)
  thumbnail_url TEXT NOT NULL,  -- Bunny CDN thumbnail
  product_link TEXT NOT NULL,  -- External product link (affiliate/commission)
  shop_name TEXT NOT NULL,  -- Store/Brand name
  description TEXT,
  views INT DEFAULT 0,  -- Track video views for analytics
  clicks INT DEFAULT 0,  -- Track link clicks for commission
  is_active BOOLEAN DEFAULT TRUE,
  display_order INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (Read Only for public users)
ALTER TABLE mart_videos ENABLE ROW LEVEL SECURITY;

-- Public read policy - everyone can see active mart videos
CREATE POLICY "Mart videos are readable by everyone" ON mart_videos
  FOR SELECT USING (is_active = true);

-- Admin only can insert/update/delete (handled in admin panel with auth checks)
-- These policies can be added after proper auth table is set up
