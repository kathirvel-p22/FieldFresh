-- Fix product display issues
-- Run this in Supabase SQL Editor

-- First, let's check the current state of ASUS products
SELECT 
    id,
    name,
    price_per_unit,
    unit,
    quantity_total,
    quantity_left,
    status,
    created_at
FROM products 
WHERE name LIKE '%asus%' OR name LIKE '%tuf%'
ORDER BY created_at DESC;

-- If quantity_left is 0 but no orders exist, fix it
UPDATE products 
SET quantity_left = quantity_total,
    status = 'active'
WHERE (name LIKE '%asus%' OR name LIKE '%tuf%')
  AND quantity_left = 0 
  AND quantity_total > 0
  AND id NOT IN (
    SELECT DISTINCT product_id 
    FROM orders 
    WHERE product_id IS NOT NULL
  );

-- Verify the fix
SELECT 
    id,
    name,
    price_per_unit,
    unit,
    quantity_total,
    quantity_left,
    status,
    'FIXED' as action
FROM products 
WHERE name LIKE '%asus%' OR name LIKE '%tuf%'
ORDER BY created_at DESC;