-- Backfill Platform Transactions for Existing Delivered Orders
-- Run this in Supabase SQL Editor

-- Create platform transactions for all delivered orders that don't have one yet
INSERT INTO platform_transactions (
  order_id,
  customer_id,
  customer_name,
  farmer_id,
  farmer_name,
  product_name,
  order_amount,
  platform_fee,
  farmer_receives,
  transaction_type,
  status,
  created_at
)
SELECT 
  o.id as order_id,
  o.customer_id,
  COALESCE(o.customer_name, c.name, 'Customer') as customer_name,
  o.farmer_id,
  f.name as farmer_name,
  o.product_name,
  o.total_amount as order_amount,
  o.total_amount * 0.05 as platform_fee,
  o.total_amount * 0.95 as farmer_receives,
  'order_delivery' as transaction_type,
  'completed' as status,
  COALESCE(o.delivered_at, o.created_at) as created_at
FROM orders o
LEFT JOIN users c ON o.customer_id = c.id
LEFT JOIN users f ON o.farmer_id = f.id
WHERE o.status = 'delivered'
  AND NOT EXISTS (
    SELECT 1 FROM platform_transactions pt 
    WHERE pt.order_id = o.id
  );

-- Verify the results
SELECT 'Platform transactions created!' as info;
SELECT 
  COUNT(*) as total_transactions,
  SUM(platform_fee) as total_platform_fees,
  SUM(order_amount) as total_order_amount
FROM platform_transactions;

SELECT '✅ Backfill complete! Refresh Revenue tab to see transactions.' as result;
