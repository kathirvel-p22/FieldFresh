# Quick Fix: Revenue Tab Not Showing Platform Fees

## The Problem
You can see delivered orders in admin panel, but Revenue tab shows ₹0 platform fees.

## The Solution (2 Minutes)

### Step 1: Run SQL in Supabase
1. Go to: https://supabase.com/dashboard
2. Select project: `ngwdvadjnnnnszqqbacn`
3. Click "SQL Editor" (left sidebar)
4. Click "New Query"
5. Copy this SQL:

```sql
INSERT INTO platform_transactions (
  order_id, customer_id, customer_name, farmer_id, farmer_name,
  product_name, order_amount, platform_fee, farmer_receives,
  transaction_type, status, created_at
)
SELECT 
  o.id, o.customer_id, COALESCE(o.customer_name, c.name, 'Customer'),
  o.farmer_id, f.name, o.product_name, o.total_amount,
  o.total_amount * 0.05, o.total_amount * 0.95,
  'order_delivery', 'completed', COALESCE(o.delivered_at, o.created_at)
FROM orders o
LEFT JOIN users c ON o.customer_id = c.id
LEFT JOIN users f ON o.farmer_id = f.id
WHERE o.status = 'delivered'
  AND NOT EXISTS (SELECT 1 FROM platform_transactions pt WHERE pt.order_id = o.id);
```

6. Click "Run" button
7. Wait for success message

### Step 2: Refresh Revenue Tab
1. Go back to your Flutter app
2. Login as Admin (tap logo 5x, enter: admin123)
3. Click Revenue tab
4. Click refresh button (top right)
5. ✅ Done! You should see all platform fees!

## What This Does
- Creates platform transaction records for all existing delivered orders
- Calculates 5% platform fee for each order
- Shows customer name, farmer name, and order details
- Only runs once (won't create duplicates)

## Future Orders
From now on, every time a customer confirms delivery, the platform transaction is automatically created. You only need to run this SQL once!

## Expected Results
After running SQL, you should see:
- Total order amounts
- Platform fees (5% of each order)
- List of all delivered orders
- Customer and farmer names
- Delivery dates

## Need Help?
Check `FIX_REVENUE_TAB.md` for detailed instructions with screenshots.
