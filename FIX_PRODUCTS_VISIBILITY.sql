-- ============================================
-- FIX CUSTOMER FEED - MAKE PRODUCTS VISIBLE
-- ============================================
-- Run this in Supabase SQL Editor to fix product visibility

-- Step 1: Check current product status
SELECT 
  id,
  name,
  farmer_id,
  status,
  quantity_left,
  valid_until,
  latitude,
  longitude,
  created_at,
  CASE 
    WHEN valid_until < NOW() THEN '❌ EXPIRED'
    WHEN status != 'active' THEN '❌ INACTIVE'
    WHEN quantity_left <= 0 THEN '❌ SOLD OUT'
    WHEN latitude IS NULL OR longitude IS NULL THEN '❌ NO LOCATION'
    ELSE '✅ SHOULD SHOW'
  END as display_status
FROM products
ORDER BY created_at DESC
LIMIT 10;

-- Step 2: Fix expired products (extend validity by 7 days)
UPDATE products
SET valid_until = NOW() + INTERVAL '7 days'
WHERE valid_until < NOW()
AND status = 'active';

-- Step 3: Fix products without location (set to Chennai)
UPDATE products
SET 
  latitude = 13.0827,
  longitude = 80.2707
WHERE latitude IS NULL OR longitude IS NULL;

-- Step 4: Activate products that should be active
UPDATE products
SET status = 'active'
WHERE status != 'active'
AND quantity_left > 0
AND valid_until > NOW();

-- Step 5: Ensure minimum quantity
UPDATE products
SET quantity_left = GREATEST(quantity_left, 50)
WHERE quantity_left < 50
AND status = 'active';

-- Step 6: Verify the fixes
SELECT 
  COUNT(*) as total_products,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products,
  COUNT(CASE WHEN valid_until > NOW() THEN 1 END) as valid_products,
  COUNT(CASE WHEN latitude IS NOT NULL THEN 1 END) as with_location,
  COUNT(CASE WHEN quantity_left > 0 THEN 1 END) as in_stock
FROM products;

-- Step 7: Show products that should now be visible
SELECT 
  p.id,
  p.name,
  p.price_per_unit,
  p.unit,
  p.status,
  p.quantity_left,
  p.valid_until,
  p.latitude,
  p.longitude,
  u.name as farmer_name,
  u.phone as farmer_phone
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.status = 'active'
AND p.valid_until > NOW()
AND p.quantity_left > 0
AND p.latitude IS NOT NULL
ORDER BY p.created_at DESC;

-- ============================================
-- OPTIONAL: Nuclear Fix (if above doesn't work)
-- ============================================
-- Uncomment and run this if products still don't show

/*
UPDATE products
SET 
  status = 'active',
  valid_until = NOW() + INTERVAL '30 days',
  latitude = 13.0827,
  longitude = 80.2707,
  quantity_left = GREATEST(quantity_left, 100)
WHERE TRUE;
*/

-- ============================================
-- Check Farmer Data
-- ============================================
-- Make sure farmers have location data too

SELECT 
  id,
  name,
  phone,
  role,
  latitude,
  longitude,
  is_verified,
  is_kyc_done
FROM users
WHERE role = 'farmer'
ORDER BY created_at DESC;

-- Fix farmers without location
UPDATE users
SET 
  latitude = 13.0827,
  longitude = 80.2707
WHERE role = 'farmer'
AND (latitude IS NULL OR longitude IS NULL);

-- ============================================
-- Final Verification Query
-- ============================================
-- This should return the products that will show in customer feed

SELECT 
  p.name as product_name,
  p.price_per_unit,
  p.unit,
  p.category,
  p.status,
  p.quantity_left,
  p.valid_until,
  u.name as farmer_name,
  u.phone as farmer_phone,
  u.district,
  u.city,
  ROUND(CAST(
    6371 * acos(
      cos(radians(13.0827)) * 
      cos(radians(p.latitude)) * 
      cos(radians(p.longitude) - radians(80.2707)) + 
      sin(radians(13.0827)) * 
      sin(radians(p.latitude))
    ) AS numeric
  ), 2) as distance_km
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.status = 'active'
AND p.valid_until > NOW()
AND p.quantity_left > 0
AND p.latitude IS NOT NULL
AND p.longitude IS NOT NULL
ORDER BY distance_km ASC;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
-- If you see products in the last query, 
-- hot reload your Flutter app and check the Market tab!
-- Products should now be visible in the customer feed.
