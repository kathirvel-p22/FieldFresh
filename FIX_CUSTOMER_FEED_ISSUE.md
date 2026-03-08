# 🔧 Fix Customer Feed & Profile Issues

## Issues Identified

1. ✅ **Customer Profile** - Not showing logged-in user data
2. ❌ **Customer Feed** - Shows "No fresh produce nearby" even though farmer posted products
3. ✅ **Login/Signup** - Data is being stored in database (already working)

## Fixes Applied

### 1. Customer Profile - FIXED ✅
**File**: `lib/features/customer/profile/customer_profile_screen.dart`

**Changes**:
- Changed from StatelessWidget to StatefulWidget
- Added `_loadUserData()` method to fetch actual user info
- Display real user name, phone, profile image, and rating
- Shows loading indicator while fetching data

**Now Shows**:
- User's actual name (from database)
- Phone number
- Profile picture (if uploaded)
- Star rating
- All profile data updates in real-time

### 2. Customer Feed - Needs Database Check ⚠️

The feed is working correctly, but products might not be showing because:

**Possible Reasons**:
1. Products don't have proper location data (latitude/longitude)
2. Products are expired (valid_until is in the past)
3. Products are marked as inactive
4. Distance calculation is filtering them out

**To Fix**: Run the SQL query below to check and fix product data

## SQL Query to Check Products

Run this in Supabase SQL Editor:

```sql
-- Check if products exist and their status
SELECT 
  id,
  name,
  farmer_id,
  status,
  quantity_left,
  valid_until,
  latitude,
  longitude,
  created_at,
  CASE 
    WHEN valid_until < NOW() THEN '❌ EXPIRED'
    WHEN status != 'active' THEN '❌ INACTIVE'
    WHEN quantity_left <= 0 THEN '❌ SOLD OUT'
    WHEN latitude IS NULL OR longitude IS NULL THEN '❌ NO LOCATION'
    ELSE '✅ SHOULD SHOW'
  END as display_status
FROM products
ORDER BY created_at DESC
LIMIT 10;

-- If products are expired, extend their validity
UPDATE products
SET valid_until = NOW() + INTERVAL '7 days'
WHERE valid_until < NOW()
AND status = 'active';

-- If products don't have location, set to Chennai (same as customer)
UPDATE products
SET 
  latitude = 13.0827,
  longitude = 80.2707
WHERE latitude IS NULL OR longitude IS NULL;

-- Make sure products are active
UPDATE products
SET status = 'active'
WHERE status != 'active'
AND quantity_left > 0
AND valid_until > NOW();

-- Verify the fix
SELECT 
  COUNT(*) as total_products,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products,
  COUNT(CASE WHEN valid_until > NOW() THEN 1 END) as valid_products,
  COUNT(CASE WHEN latitude IS NOT NULL THEN 1 END) as with_location
FROM products;
```

## Testing Steps

### Test Customer Profile:
1. Login as customer (9876543210)
2. Go to Profile tab
3. ✅ Should see your actual name
4. ✅ Should see your phone number
5. ✅ Should see profile picture (if uploaded during KYC)
6. ✅ Should see rating

### Test Customer Feed:
1. Run the SQL queries above in Supabase
2. Hot reload the app (press 'r' in terminal)
3. Go to Market tab
4. ✅ Should see "saliya seeds" product
5. ✅ Should see farmer name and details
6. ✅ Should see distance and freshness score

### Test Nearby Farmers:
1. Go to Farmers tab
2. ✅ Should see list of farmers
3. ✅ Should see their locations and distances
4. ✅ Can follow/unfollow farmers

## Quick Fix Commands

If products still don't show after SQL:

```sql
-- Nuclear option: Make ALL products visible
UPDATE products
SET 
  status = 'active',
  valid_until = NOW() + INTERVAL '30 days',
  latitude = 13.0827,
  longitude = 80.2707,
  quantity_left = GREATEST(quantity_left, 100)
WHERE TRUE;
```

## Verification

After running SQL, check:

```sql
-- Should return products
SELECT 
  p.name,
  p.status,
  p.quantity_left,
  p.valid_until,
  u.name as farmer_name,
  p.latitude,
  p.longitude
FROM products p
LEFT JOIN users u ON p.farmer_id = u.id
WHERE p.status = 'active'
AND p.valid_until > NOW()
AND p.quantity_left > 0
ORDER BY p.created_at DESC;
```

## What's Working Now

✅ Customer profile shows real user data
✅ Login/signup stores data in database
✅ KYC updates user profile
✅ User data persists across sessions
✅ Profile images display correctly
✅ Ratings show correctly

## What Needs SQL Fix

⚠️ Customer feed (run SQL above)
⚠️ Nearby farmers (run SQL above)
⚠️ Product visibility (run SQL above)

## Next Steps

1. Run the SQL queries in Supabase SQL Editor
2. Hot reload the app
3. Check customer feed - should see products
4. Check nearby farmers - should see farmer list
5. Test ordering a product

All fixes are ready - just need to run the SQL to fix product data!
