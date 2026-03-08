-- ============================================
-- ADD COMPLETE LOCATION FIELDS TO USERS TABLE
-- ============================================
-- Run this in Supabase SQL Editor

-- Add location columns if they don't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS village VARCHAR(100),
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS district VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(100);

-- Update existing users with default location (Chennai, Tamil Nadu)
UPDATE users
SET 
  village = COALESCE(village, 'Demo Village'),
  city = COALESCE(city, 'Chennai'),
  district = COALESCE(district, 'Chennai'),
  state = COALESCE(state, 'Tamil Nadu')
WHERE village IS NULL OR city IS NULL OR district IS NULL OR state IS NULL;

-- Verify the changes
SELECT 
  id,
  name,
  phone,
  role,
  village,
  city,
  district,
  state,
  latitude,
  longitude
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- SUCCESS! Location fields added to all users
-- Now users will show complete address details
-- ============================================
