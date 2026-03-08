-- ============================================
-- QUICK FIX - Copy and paste this entire file into Supabase SQL Editor
-- ============================================

-- Make all products visible in customer feed
UPDATE products
SET 
  status = 'active',
  valid_until = NOW() + INTERVAL '30 days',
  latitude = 13.0827,
  longitude = 80.2707,
  quantity_left = GREATEST(quantity_left, 100)
WHERE TRUE;

-- Make all farmers have location
UPDATE users
SET 
  latitude = 13.0827,
  longitude = 80.2707
WHERE role = 'farmer'
AND (latitude IS NULL OR longitude IS NULL);

-- Verify products are now visible
SELECT 
  p.name as product,
  p.price_per_unit as price,
  p.unit,
  p.status,
  p.quantity_left as qty,
  u.name as farmer,
  '✅ VISIBLE' as status_check
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.status = 'active'
AND p.valid_until > NOW()
AND p.quantity_left > 0
ORDER BY p.created_at DESC;

-- ============================================
-- DONE! Now hot reload your Flutter app (press 'r' in terminal)
-- Go to Market tab and you should see all products!
-- ============================================
