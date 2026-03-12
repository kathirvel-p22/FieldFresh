-- Check how many farmers exist in the database
SELECT 
  COUNT(*) as total_farmers,
  COUNT(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 END) as farmers_with_location,
  COUNT(CASE WHEN latitude IS NULL OR longitude IS NULL THEN 1 END) as farmers_without_location
FROM users 
WHERE role = 'farmer';

-- List all farmers and their details
SELECT 
  id,
  name,
  latitude,
  longitude,
  city,
  district,
  is_verified,
  created_at
FROM users 
WHERE role = 'farmer'
ORDER BY name;

-- Check how many products exist and their farmers
SELECT 
  COUNT(*) as total_products,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products,
  COUNT(DISTINCT farmer_id) as unique_farmers_with_products
FROM products;

-- List all active products with farmer names
SELECT 
  p.id,
  p.name as product_name,
  p.category,
  p.status,
  p.quantity_left,
  u.name as farmer_name,
  u.latitude as farmer_lat,
  u.longitude as farmer_lng,
  p.created_at
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.status = 'active'
ORDER BY p.created_at DESC;

-- Find products without farmer data (orphaned products)
SELECT 
  p.id,
  p.name,
  p.farmer_id,
  'NO FARMER FOUND' as issue
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE u.id IS NULL;

-- Check if Somesh farmer exists and has products
SELECT 
  u.name as farmer_name,
  u.id as farmer_id,
  COUNT(p.id) as product_count,
  u.latitude,
  u.longitude
FROM users u
LEFT JOIN products p ON u.id = p.farmer_id AND p.status = 'active'
WHERE u.name ILIKE '%somesh%' OR u.name ILIKE '%som%'
GROUP BY u.id, u.name, u.latitude, u.longitude;