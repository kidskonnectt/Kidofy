-- Migration: Make thumbnail_path optional in videos table
-- This allows videos to be uploaded without a thumbnail

-- Alter the videos table to make thumbnail_path nullable
ALTER TABLE public.videos 
ALTER COLUMN thumbnail_path DROP NOT NULL;

-- Add a comment to clarify the change
COMMENT ON COLUMN public.videos.thumbnail_path IS 'Optional: Path in Bunny (e.g., images/thumbnails/abc.jpg). Null if no thumbnail was provided during upload.';
