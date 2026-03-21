# Fix for Farmer/Customer Deletion Error

## Problem Identified
The deletion is failing because of a **database constraint violation**:
```
PostgrestException: new row for relation 'users' violates check constraint 'users_role_check'
```

The database has a check constraint that only allows specific role values, and `inactive_farmer`/`inactive_customer` are not permitted.

## Solution Implemented

I've updated the code to use the `is_active` field instead of changing roles, which avoids the constraint issue entirely.

### Code Changes Made:

1. **Updated `deleteFarmer()` method**: Now sets `is_active = false` instead of changing role
2. **Updated `deleteCustomer()` method**: Now sets `is_active = false` instead of changing role  
3. **Updated `getAllFarmers()`**: Now filters by `is_active != false`
4. **Updated `getAllCustomers()`**: Now filters by `is_active != false`
5. **Updated restore methods**: Now sets `is_active = true`

### Database Setup Required:

You need to run **ONE** of these SQL scripts in your Supabase database:

#### Option 1: Fix Role Constraint (Recommended)
```sql
-- Run this in Supabase SQL Editor
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('farmer', 'customer', 'admin', 'inactive_farmer', 'inactive_customer'));
```

#### Option 2: Add is_active Field (Alternative)
```sql
-- Run this in Supabase SQL Editor  
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
UPDATE users SET is_active = true WHERE is_active IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
```

## How It Works Now:

### For Farmers with Orders (like Ramu, Geetha Devi):
1. ✅ Keeps role as 'farmer' (no constraint violation)
2. ✅ Sets `is_active = false` (soft delete)
3. ✅ Marks their products as 'deleted' status
4. ✅ Preserves all order history
5. ✅ Farmer disappears from admin list but data remains

### For Users without Orders:
1. ✅ Complete deletion (hard delete)
2. ✅ No constraint violations

## Testing Steps:

1. **Run the database script** (choose Option 1 or 2 above)
2. **Refresh your app** 
3. **Try deleting Ramu farmer** - should work now
4. **Try deleting Geetha Devi farmer** - should work now
5. **Verify they disappear** from the farmers list
6. **Check orders remain intact** in the database

## Files Updated:
- `lib/services/supabase_service.dart` - Updated deletion logic
- `DELETION_CONSTRAINT_FIX_COMPLETE.sql` - Database fix script
- `ADD_IS_ACTIVE_FIELD.sql` - Alternative database script

The deletion should now work without any constraint violations!