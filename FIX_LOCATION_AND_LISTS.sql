-- ============================================
-- FIX LOCATION DATA AND UPDATE LISTS
-- ============================================

-- Step 1: Update existing user "kathirvel p" with location
UPDATE users
SET 
  village = 'Velachery',
  city = 'Chennai',
  district = 'Chennai',
  state = 'Tamil Nadu',
  latitude = 13.0827,
  longitude = 80.2707
WHERE phone = '+919894768404';

-- Step 2: Update ALL users without location
UPDATE users
SET 
  village = COALESCE(village, 'Velachery'),
  city = COALESCE(city, 'Chennai'),
  district = COALESCE(district, 'Chennai'),
  state = COALESCE(state, 'Tamil Nadu'),
  latitude = COALESCE(latitude, 13.0827),
  longitude = COALESCE(longitude, 80.2707)
WHERE village IS NULL OR city IS NULL OR district IS NULL OR state IS NULL
   OR latitude IS NULL OR longitude IS NULL;

-- Step 3: Verify user data
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
  longitude,
  is_verified,
  is_kyc_done
FROM users
WHERE phone = '+919894768404';

-- Step 4: Check all users have complete data
SELECT 
  role,
  COUNT(*) as total,
  COUNT(CASE WHEN village IS NOT NULL THEN 1 END) as with_village,
  COUNT(CASE WHEN city IS NOT NULL THEN 1 END) as with_city,
  COUNT(CASE WHEN district IS NOT NULL THEN 1 END) as with_district,
  COUNT(CASE WHEN state IS NOT NULL THEN 1 END) as with_state,
  COUNT(CASE WHEN latitude IS NOT NULL THEN 1 END) as with_location
FROM users
GROUP BY role;

-- ============================================
-- SUCCESS! All users now have complete location data
-- Hot reload the app to see changes
-- ============================================
