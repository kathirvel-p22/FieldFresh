-- Debug script to check why products can't be deleted
-- Run these queries to identify the issue

-- 1. Check the current products that are marked as deleted
SELECT 
    id, 
    name, 
    farmer_id, 
    status,
    created_at,
    (SELECT name FROM users WHERE id = products.farmer_id) as farmer_name
FROM products 
WHERE status = 'deleted'
ORDER BY created_at DESC;

-- 2. Check if there are any orders referencing these products
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.status,
    COUNT(o.id) as order_count,
    STRING_AGG(o.id::text, ', ') as order_ids
FROM products p
LEFT JOIN orders o ON o.product_id = p.id
WHERE p.status = 'deleted'
GROUP BY p.id, p.name, p.status
ORDER BY order_count DESC;

-- 3. Check for any other foreign key references that might prevent deletion
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND ccu.table_name = 'products';

-- 4. Check if there are any reviews, cart items, or other references
SELECT 'reviews' as table_name, COUNT(*) as count 
FROM reviews r 
JOIN orders o ON r.order_id = o.id 
JOIN products p ON o.product_id = p.id 
WHERE p.status = 'deleted'

UNION ALL

SELECT 'group_buys' as table_name, COUNT(*) as count
FROM group_buys gb
JOIN products p ON gb.product_id = p.id
WHERE p.status = 'deleted';