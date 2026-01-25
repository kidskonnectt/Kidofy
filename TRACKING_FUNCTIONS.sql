-- Tracking Functions for Views and Clicks
-- Run these in Supabase SQL Editor

-- Function to increment mart video views
CREATE OR REPLACE FUNCTION increment_mart_views(p_id INT)
RETURNS INT AS $$
BEGIN
  UPDATE mart_videos 
  SET views = views + 1,
      updated_at = NOW()
  WHERE id = p_id;
  
  RETURN (SELECT views FROM mart_videos WHERE id = p_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment mart video clicks
CREATE OR REPLACE FUNCTION increment_mart_clicks(p_id INT)
RETURNS INT AS $$
BEGIN
  UPDATE mart_videos 
  SET clicks = clicks + 1,
      updated_at = NOW()
  WHERE id = p_id;
  
  RETURN (SELECT clicks FROM mart_videos WHERE id = p_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment video views
CREATE OR REPLACE FUNCTION increment_video_views(p_id BIGINT)
RETURNS INT AS $$
BEGIN
  UPDATE videos 
  SET views = views + 1
  WHERE id = p_id;
  
  RETURN (SELECT views FROM videos WHERE id = p_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment video likes
CREATE OR REPLACE FUNCTION increment_video_likes(p_id BIGINT)
RETURNS INT AS $$
BEGIN
  UPDATE videos 
  SET likes = likes + 1
  WHERE id = p_id;
  
  RETURN (SELECT likes FROM videos WHERE id = p_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment video dislikes
CREATE OR REPLACE FUNCTION increment_video_dislikes(p_id BIGINT)
RETURNS INT AS $$
BEGIN
  UPDATE videos 
  SET dislikes = dislikes + 1
  WHERE id = p_id;
  
  RETURN (SELECT dislikes FROM videos WHERE id = p_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users for mart tracking
GRANT EXECUTE ON FUNCTION increment_mart_views(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_mart_clicks(INT) TO authenticated;

-- Grant execute permission to authenticated users for video tracking
GRANT EXECUTE ON FUNCTION increment_video_views(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_video_likes(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_video_dislikes(BIGINT) TO authenticated;

-- Optional: Allow anonymous users to track views (for unauthenticated users)
GRANT EXECUTE ON FUNCTION increment_mart_views(INT) TO anon;
GRANT EXECUTE ON FUNCTION increment_mart_clicks(INT) TO anon;
GRANT EXECUTE ON FUNCTION increment_video_views(BIGINT) TO anon;
