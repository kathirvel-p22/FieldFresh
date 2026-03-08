-- ============================================
-- COMPLETE FIX - Run this entire file in Supabase SQL Editor
-- This fixes: Products visibility + Location fields + Sample data
-- ============================================

-- PART 1: Add location columns to users table
-- ============================================
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS village VARCHAR(100),
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS district VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(100);

-- PART 2: Update existing users with default location
-- ============================================
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

-- PART 3: Fix all products to be visible
-- ============================================
UPDATE products
SET 
  status = 'active',
  valid_until = NOW() + INTERVAL '30 days',
  latitude = COALESCE(latitude, 13.0827),
  longitude = COALESCE(longitude, 80.2707),
  quantity_left = GREATEST(quantity_left, 100)
WHERE TRUE;

-- PART 4: Verify users have complete data
-- ============================================
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
ORDER BY created_at DESC
LIMIT 10;

-- PART 5: Verify products are visible
-- ============================================
SELECT 
  p.name as product,
  p.price_per_unit as price,
  p.unit,
  p.status,
  p.quantity_left as qty,
  p.valid_until,
  u.name as farmer,
  u.village,
  u.city,
  u.district,
  '✅ VISIBLE' as status_check
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.status = 'active'
AND p.valid_until > NOW()
AND p.quantity_left > 0
ORDER BY p.created_at DESC;

-- PART 6: Check orders (if any)
-- ============================================
SELECT 
  o.id,
  o.product_name,
  o.quantity,
  o.total_amount,
  o.status,
  c.name as customer_name,
  c.phone as customer_phone,
  c.village as customer_village,
  c.city as customer_city,
  f.name as farmer_name
FROM orders o
LEFT JOIN users c ON o.customer_id = c.id
LEFT JOIN users f ON o.farmer_id = f.id
ORDER BY o.created_at DESC
LIMIT 10;

-- ============================================
-- DONE! Summary of changes:
-- ============================================
-- ✅ Added location fields (village, city, district, state)
-- ✅ Updated all users with default Chennai location
-- ✅ Made all products visible and active
-- ✅ Extended product validity by 30 days
-- ✅ Set product locations to Chennai
-- ✅ Ensured minimum stock quantity

-- ============================================
-- Next Steps:
-- ============================================
-- 1. Hot reload your Flutter app (press 'r' in terminal)
-- 2. Login as customer (9876543210)
-- 3. Check Market tab - should see products
-- 4. Check Profile - should see complete location
-- 5. Login as farmer (9876543211)
-- 6. Check Profile - should see complete location
-- 7. Check Customer Orders - should see any orders placed
-- ============================================
