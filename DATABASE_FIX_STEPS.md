# 🔧 Database Fix - Step by Step Guide

## 🚨 CURRENT ISSUE
**Error**: `null value in column "quantity_total" violates not-null constraint`

**Root Cause**: Your current Supabase database doesn't have the correct schema. The app expects fields like `quantity_total`, `quantity_left`, `price_per_unit` but your database has different field names.

## 🛠️ IMMEDIATE FIX - Apply Database Schema

### Step 1: Open Supabase Dashboard
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your project: `ngwdvadjnnnnszqqbacn`

### Step 2: Access SQL Editor
1. In the left sidebar, click **"SQL Editor"**
2. Click **"New Query"** button

### Step 3: Run Complete Database Schema
1. Open the file `SUPABASE_DATABASE_SCHEMA.sql` in your project
2. **Copy the ENTIRE content** (all 400+ lines)
3. **Paste it** into the Supabase SQL Editor
4. Click **"Run"** button

### Step 4: Verify Tables Created
After running the schema, you should see:
```
✅ users table created/updated
✅ products table created/updated  
✅ orders table created/updated
✅ reviews table created/updated
✅ cart_items table created/updated
✅ notifications table created/updated
✅ wallet_transactions table created/updated
✅ farmer_followers table created/updated
✅ payment_settings table created/updated
✅ platform_transactions table created/updated
✅ community_groups table created/updated
✅ group_messages table created/updated
```

## 🔍 WHAT THE SCHEMA FIXES

### Products Table - Correct Fields
The schema creates the products table with these exact fields:
- `id` (UUID, Primary Key)
- `farmer_id` (UUID, Foreign Key)
- `name` (VARCHAR)
- `category` (VARCHAR)
- `description` (TEXT)
- `price_per_unit` (DECIMAL) ← This field was missing
- `unit` (VARCHAR)
- `quantity_total` (DECIMAL) ← This field was missing
- `quantity_left` (DECIMAL) ← This field was missing
- `image_urls` (TEXT[])
- `harvest_time` (TIMESTAMP)
- `valid_until` (TIMESTAMP)
- `freshness_score` (INTEGER)
- `latitude` (DECIMAL)
- `longitude` (DECIMAL)
- `farm_address` (TEXT)
- `status` (VARCHAR)
- `order_count` (INTEGER)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Enhanced Compatibility
I've also updated the app's database service to:
1. **Try new schema first** (with correct field names)
2. **Fallback to legacy names** (if old schema exists)
3. **Ultra-minimal insert** (to discover current schema)
4. **Better error messages** (to guide you to the fix)

## 🧪 TESTING AFTER FIX

### Step 1: Test Product Posting
1. Fill out the product form completely:
   - Product Name: "Fresh Tomatoes"
   - Price: 50
   - Quantity: 10
   - Add a photo
   - Ensure location is detected
2. Click "Post Harvest"
3. Should see: "🌾 Harvest posted! Nearby customers notified!"

### Step 2: Verify in Database
1. In Supabase Dashboard, go to **"Table Editor"**
2. Select **"products"** table
3. You should see your posted product with all fields filled

### Step 3: Test Customer View
1. Login as customer (phone: 9876543210)
2. Go to customer feed
3. Should see the posted product

## 🚀 ALTERNATIVE QUICK FIX (If Schema Fails)

If running the full schema doesn't work, try this minimal fix:

```sql
-- Add missing columns to existing products table
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS quantity_total DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS quantity_left DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS price_per_unit DECIMAL(10,2) DEFAULT 0;

-- Update existing records to have non-null values
UPDATE products SET 
  quantity_total = COALESCE(quantity_total, 0),
  quantity_left = COALESCE(quantity_left, 0),
  price_per_unit = COALESCE(price_per_unit, 0)
WHERE quantity_total IS NULL OR quantity_left IS NULL OR price_per_unit IS NULL;
```

## 📞 NEXT STEPS

1. **Run the database schema** (Step 1-4 above)
2. **Test product posting** immediately after
3. **Check browser console** for any remaining errors
4. **Let me know the result** - success or any new errors

The enhanced error handling will now show you exactly what's happening at each step!