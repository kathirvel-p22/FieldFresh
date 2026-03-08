-- Fix Farmers Visibility Issue
-- This ensures all farmers are visible in the customer panel

-- 1. Make sure all farmers are verified
UPDATE users 
SET is_verified = true 
WHERE role = 'farmer';

-- 2. Ensure all farmers have location data (Chennai coordinates)
UPDATE users 
SET 
  latitude = 13.0827,
  longitude = 80.2707,
  village = COALESCE(village, 'Valasaravakkam'),
  city = COALESCE(city, 'Chennai'),
  district = COALESCE(district, 'Chennai'),
  state = COALESCE(state, 'Tamil Nadu')
WHERE role = 'farmer' 
  AND (latitude IS NULL OR longitude IS NULL);

-- 3. Verify the data
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
  rating
FROM users 
WHERE role = 'farmer'
ORDER BY name;

-- Expected output: All farmers should have:
-- - is_verified = true
-- - latitude/longitude set
-- - Complete location details (village, city, district, state)
