-- Fix farmer coordinates - Update Somesh M and Akash B to Chennai location
-- Current issue: They have Seoul, South Korea coordinates (37.5682, 126.9977)
-- Customer location is Chennai (13.0827, 80.2707)
-- Distance is ~4600km, so they're filtered out

-- Update Somesh M to Chennai coordinates
UPDATE users 
SET 
  latitude = 13.0827,
  longitude = 80.2707,
  city = 'Chennai',
  district = 'Chennai',
  state = 'Tamil Nadu',
  address = 'Chennai, Tamil Nadu',
  updated_at = NOW()
WHERE id = '3b9be1fb-d7e4-4009-a439-bf418284976e' 
AND name = 'Somesh M';

-- Update Akash B to Chennai coordinates  
UPDATE users 
SET 
  latitude = 13.0827,
  longitude = 80.2707,
  city = 'Chennai',
  district = 'Chennai', 
  state = 'Tamil Nadu',
  address = 'Chennai, Tamil Nadu',
  updated_at = NOW()
WHERE id = '630f0d97-24cb-40a9-bb3d-72400c80560e'
AND name = 'Akash B';

-- Verify the updates
SELECT 
  id,
  name as farmer_name,
  latitude,
  longitude,
  city,
  district,
  is_verified
FROM users 
WHERE role = 'farmer'
ORDER BY name;

-- Check products for these farmers
SELECT 
  p.name as product_name,
  p.status,
  p.quantity_left,
  u.name as farmer_name,
  u.latitude,
  u.longitude
FROM products p
JOIN users u ON p.farmer_id = u.id
WHERE u.id IN ('3b9be1fb-d7e4-4009-a439-bf418284976e', '630f0d97-24cb-40a9-bb3d-72400c80560e')
AND p.status = 'active'
ORDER BY u.name, p.name;