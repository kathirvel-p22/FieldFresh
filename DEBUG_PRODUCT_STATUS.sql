-- Debug product status issues
-- Run this in Supabase SQL Editor to check product data

-- Check the actual data in products table
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

-- Check if there are any orders for these products
SELECT 
    o.id as order_id,
    o.product_name,
    o.quantity as ordered_quantity,
    o.status as order_status,
    p.name as product_name,
    p.quantity_left as current_quantity_left
FROM orders o
JOIN products p ON o.product_id = p.id
WHERE p.name LIKE '%asus%' OR p.name LIKE '%tuf%'
ORDER BY o.created_at DESC;