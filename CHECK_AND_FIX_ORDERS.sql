-- COMPLETE FIX FOR ORDERS - Run this in Supabase SQL Editor
-- This will fix farmer orders display AND add customer info

-- 1. Add ALL missing columns to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone VARCHAR(20);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

-- 2. Create platform_transactions table for admin tracking
CREATE TABLE IF NOT EXISTS platform_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES users(id),
  customer_name VARCHAR(255),
  farmer_id UUID REFERENCES users(id),
  farmer_name VARCHAR(255),
  product_name VARCHAR(255),
  order_amount DECIMAL(10,2),
  platform_fee DECIMAL(10,2),
  farmer_receives DECIMAL(10,2),
  transaction_type VARCHAR(50) DEFAULT 'order_delivery',
  status VARCHAR(50) DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disable RLS for platform_transactions
ALTER TABLE platform_transactions DISABLE ROW LEVEL SECURITY;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_platform_transactions_created ON platform_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_platform_transactions_order ON platform_transactions(order_id);

-- 3. Fix farmer_id in orders (update from products table)
UPDATE orders o
SET farmer_id = p.farmer_id
FROM products p
WHERE o.product_id = p.id
  AND (o.farmer_id IS NULL OR o.farmer_id != p.farmer_id);

-- 4. Add customer name and phone to existing orders
UPDATE orders o
SET 
  customer_name = u.name,
  customer_phone = u.phone
FROM users u
WHERE o.customer_id = u.id
  AND (o.customer_name IS NULL OR o.customer_phone IS NULL);

-- 5. Verify the fix
SELECT '✅ Orders fixed! Here are your orders:' as info;
SELECT 
  o.id,
  o.product_name,
  o.customer_name,
  o.customer_phone,
  u.name as farmer_name,
  u.phone as farmer_phone,
  o.status,
  o.total_amount,
  o.created_at
FROM orders o
LEFT JOIN users u ON o.farmer_id = u.id
ORDER BY o.created_at DESC;

SELECT '✅ Fix complete! Refresh your app (F5) to see orders.' as result;
