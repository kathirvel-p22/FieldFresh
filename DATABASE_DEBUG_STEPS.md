# Database Debug Steps for Product Posting

## Current Issue
Error: `Could not find the 'price' column of 'products' in the schema cache`

This suggests the database table structure is different from what we expected.

## Debug Changes Made

### 1. Added Debug Logging to postProduct()
- Logs the data being sent to database
- Tries minimal data first, then ultra-minimal if that fails
- Shows exactly what fields are causing issues

### 2. Added Debug Logging to getAllProducts()
- Fetches one product to see actual database structure
- Shows what fields exist in the database
- Helps understand the real table schema

### 3. Reverted Field Name Changes
- Changed back to `price_per_unit` in ProductModel
- This matches what other parts of the code expect

## How to Debug

### Step 1: Open Browser Console
1. Open Chrome
2. Press F12 to open Developer Tools
3. Go to Console tab
4. Keep it open while testing

### Step 2: Try to Post Product
1. Login as farmer (9876543211)
2. Go to Post tab
3. Fill in product details
4. Click POST button
5. Watch console for debug messages

### Step 3: Check Debug Output
Look for these messages in console:
```
Fetching all products to check database structure...
Sample product from database: {...}
Available fields: [...]
Attempting to post product with data: {...}
```

## Possible Issues & Solutions

### Issue 1: Table Doesn't Exist
**Symptoms**: Error about table not found
**Solution**: Create products table in Supabase

### Issue 2: Wrong Field Names
**Symptoms**: Field not found errors
**Solution**: Update ProductModel to match actual schema

### Issue 3: Missing Required Fields
**Symptoms**: NOT NULL constraint errors
**Solution**: Add required fields or make them optional

### Issue 4: Wrong Data Types
**Symptoms**: Type conversion errors
**Solution**: Fix data types in ProductModel

## Expected Database Schema

Based on the code, the products table should have:
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  category TEXT,
  description TEXT,
  price_per_unit DECIMAL,
  unit TEXT,
  quantity_total DECIMAL,
  quantity_left DECIMAL,
  image_urls TEXT[],
  harvest_time TIMESTAMP,
  valid_until TIMESTAMP,
  freshness_score INTEGER,
  status TEXT DEFAULT 'active',
  latitude DECIMAL,
  longitude DECIMAL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Next Steps

1. **Run the debug version** and check console output
2. **Identify the real issue** from debug messages
3. **Fix the specific problem** (table creation, field names, etc.)
4. **Remove debug code** once working
5. **Test full product posting flow**

## Debug Commands

If you have access to Supabase dashboard:

### Check if table exists:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'products';
```

### Check table structure:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'products';
```

### Check existing products:
```sql
SELECT * FROM products LIMIT 1;
```

## Status

- ✅ Debug logging added
- ✅ Field names reverted
- ⏳ Waiting for console output
- ⏳ Need to identify real issue
- ⏳ Apply proper fix

---

**Next**: Try posting a product and check browser console for debug messages!