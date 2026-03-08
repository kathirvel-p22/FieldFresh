# Fix Revenue Tab - Platform Fees Not Showing

## Problem
The admin Revenue tab is not showing platform fees for existing delivered orders.

## Why This Happens
Platform transactions are only created when a customer confirms delivery. Orders that were marked as "delivered" before this system was implemented don't have platform transaction records.

## Solution - Run This SQL in Supabase

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `ngwdvadjnnnnszqqbacn`
3. Click "SQL Editor" in the left sidebar
4. Click "New Query"
5. Copy and paste the SQL below
6. Click "Run" button

```sql
-- Backfill Platform Transactions for Existing Delivered Orders
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
SELECT 
  COUNT(*) as total_transactions,
  SUM(platform_fee) as total_platform_fees,
  SUM(order_amount) as total_order_amount
FROM platform_transactions;
```

## After Running SQL

1. Go back to your Flutter app
2. Login as Admin (tap logo 5x, code: admin123)
3. Go to Revenue tab
4. Pull down to refresh
5. You should now see all platform transactions!

## How It Works Going Forward

From now on, whenever a customer confirms delivery:
1. Order status changes to "delivered"
2. Platform transaction is automatically created
3. Admin Revenue tab updates in real-time
4. Platform fee (5%) is recorded for admin tracking

## Summary

- Platform fee: 5% of order amount
- Farmer receives: 95% of order amount
- All future deliveries will automatically create platform transactions
- This SQL only needs to be run once to backfill existing orders
