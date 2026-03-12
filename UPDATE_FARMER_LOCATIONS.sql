-- Update all farmers to have default Chennai location if they don't have coordinates
-- This ensures all farmers appear in the marketplace regardless of location data

-- First, let's see which farmers don't have location data
SELECT id, name, latitude, longitude, role 
FROM users 
WHERE role = 'farmer' 
AND (latitude IS NULL OR longitude IS NULL);

-- Update farmers without location to have default Chennai coordinates
UPDATE users 
SET 
  latitude = 13.0827,
  longitude = 80.2707,
  city = 'Chennai',
  district = 'Chennai',
  state = 'Tamil Nadu',
  address = COALESCE(address, 'Chennai, Tamil Nadu'),
  updated_at = NOW()
WHERE role = 'farmer' 
AND (latitude IS NULL OR longitude IS NULL);

-- Verify the update
SELECT id, name, latitude, longitude, city, district 
FROM users 
WHERE role = 'farmer' 
ORDER BY name;

-- Also update any products that might not have location data
UPDATE products 
SET 
  latitude = 13.0827,
  longitude = 80.2707,
  updated_at = NOW()
WHERE latitude IS NULL OR longitude IS NULL;

-- Check if there are any products without farmer references
SELECT p.id, p.name, p.farmer_id, u.name as farmer_name
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE u.id IS NULL;

-- Show all farmers and their product counts
SELECT 
  u.id,
  u.name as farmer_name,
  u.latitude,
  u.longitude,
  u.is_verified,
  COUNT(p.id) as product_count
FROM users u
LEFT JOIN products p ON u.id = p.farmer_id AND p.status = 'active'
WHERE u.role = 'farmer'
GROUP BY u.id, u.name, u.latitude, u.longitude, u.is_verified
ORDER BY u.name;