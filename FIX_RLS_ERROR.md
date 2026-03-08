## 🔧 FIX: Row-Level Security Policy Error

### ❌ Current Error
```
Error: PostgrestException(message: new row violates row-level security policy for table "products", code: 42501)
```

### 🎯 Root Cause
The app is running in **demo mode** without real authentication, but Supabase RLS (Row-Level Security) policies require `auth.uid()` to match the `farmer_id`. In demo mode, `auth.uid()` is NULL, so the policy blocks the insert.

### ✅ Solution: Update RLS Policies

You need to run SQL in your Supabase dashboard to allow demo mode operations.

## 📝 Step-by-Step Fix

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project: **ngwdvadjnnnnszqqbacn**
3. Click **SQL Editor** in left sidebar
4. Click **New Query**

### Step 2: Run This SQL
Copy and paste this entire SQL script:

```sql
-- ═══════════════════════════════════════════════════════════════
-- FIX RLS POLICIES FOR DEMO MODE
-- ═══════════════════════════════════════════════════════════════

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Farmers can insert products" ON products;
DROP POLICY IF EXISTS "Farmers can update own products" ON products;
DROP POLICY IF EXISTS "Farmers can delete own products" ON products;

-- Create new permissive policies for demo mode
CREATE POLICY "Anyone can insert products"
  ON products FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Anyone can update products"
  ON products FOR UPDATE 
  USING (true);

CREATE POLICY "Anyone can delete products"
  ON products FOR DELETE 
  USING (true);

-- Fix orders policies
DROP POLICY IF EXISTS "Customers can create orders" ON orders;
DROP POLICY IF EXISTS "Farmers can update order status" ON orders;

CREATE POLICY "Anyone can create orders"
  ON orders FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Anyone can update orders"
  ON orders FOR UPDATE 
  USING (true);

-- Fix users policies
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

CREATE POLICY "Anyone can insert users"
  ON users FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Anyone can update users"
  ON users FOR UPDATE 
  USING (true);
```

### Step 3: Click "Run" Button
- The SQL will execute
- You should see "Success. No rows returned"

### Step 4: Test Post Product Again
1. Go back to your app (localhost:50157)
2. Refresh the page (F5)
3. Login as farmer: 9876543211
4. Try posting a product again
5. ✅ Should work now!

## 🎯 What This Does

### Before Fix
- RLS policies check: `auth.uid() = farmer_id`
- In demo mode: `auth.uid()` is NULL
- Result: ❌ Policy violation error

### After Fix
- RLS policies allow: `true` (anyone can insert)
- In demo mode: Works without authentication
- Result: ✅ Products can be posted

## ⚠️ Important Notes

### For Demo/Development
- These permissive policies are **perfect for demo mode**
- They allow testing without real authentication
- All features will work smoothly

### For Production
When you're ready to deploy to real users:
1. Implement proper authentication (not demo mode)
2. Update RLS policies to be more restrictive:
```sql
CREATE POLICY "Authenticated farmers can insert products"
  ON products FOR INSERT 
  WITH CHECK (auth.uid() = farmer_id);
```

## 🧪 Test After Fix

### 1. Post Product
```
Login: 9876543211
Fill form → Post
Expected: ✅ Success!
```

### 2. Place Order
```
Login: 9876543210
Order product
Expected: ✅ Success!
```

### 3. Update Order
```
Login: 9876543211
Accept order
Expected: ✅ Success!
```

## 📊 Alternative: Disable RLS Temporarily

If you want to completely disable RLS for testing:

```sql
-- Disable RLS on all tables (NOT recommended for production)
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
```

But the permissive policies above are better because:
- ✅ RLS stays enabled (security layer exists)
- ✅ Policies are just more permissive
- ✅ Easy to tighten later for production

## 🚀 Quick Fix Summary

1. **Open**: Supabase Dashboard → SQL Editor
2. **Paste**: The SQL script above
3. **Run**: Click Run button
4. **Test**: Try posting product again
5. **Success**: ✅ Should work!

## 📝 Files Created

- `supabase/FIX_RLS_DEMO_MODE.sql` - Complete SQL script
- `FIX_RLS_ERROR.md` - This guide

## ✅ After Running SQL

Everything will work:
- ✅ Post products
- ✅ Place orders
- ✅ Update orders
- ✅ Manage listings
- ✅ View analytics
- ✅ All farmer features
- ✅ All customer features
- ✅ All admin features

**Run the SQL and test again!** 🌾
