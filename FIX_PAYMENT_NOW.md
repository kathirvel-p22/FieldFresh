# 🎯 Fix Payment Error - 2 Minutes

## Error You're Seeing
```
Payment Failed
PostgrestException(message: Could not find the 'delivery_charge' column of 'orders' in the schema cache
```

## The Fix (Copy & Paste)

### Step 1: Open Supabase
1. Go to: https://supabase.com/dashboard
2. Click your project: **ngwdvadjnnnnszqqbacn**
3. Click **"SQL Editor"** (left sidebar)
4. Click **"+ New Query"**

### Step 2: Copy This SQL
Open the file **`COMPLETE_DATABASE_FIX.sql`** in your editor and copy ALL the text.

### Step 3: Paste and Run
1. Paste into Supabase SQL Editor
2. Click **"Run"** button (or Ctrl+Enter)
3. Wait for success message: "✅ ALL DATABASE FIXES COMPLETE!"

### Step 4: Refresh Your App
Press **F5** in your browser

### Step 5: Complete Purchase
1. Go back to checkout
2. Click **"Pay ₹445"**
3. Enter PIN (1234 or any 4 digits)
4. ✅ **SUCCESS!** Order will complete

## What This Fixes

The SQL adds these missing columns to `orders` table:
- `delivery_charge` ← This was causing your error
- `platform_fee`
- `payment_method`
- `transaction_id`

Plus creates missing tables:
- `farmer_followers`
- Adds `sent_at` to `notifications`
- Adds `expires_at` to `group_buys`

## After Running SQL

You'll see this output in Supabase:
```
✅ ALL DATABASE FIXES COMPLETE! You can now complete your purchase.
```

Then your payment will work perfectly! 🎉
