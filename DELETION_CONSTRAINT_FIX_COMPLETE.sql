-- COMPLETE FIX for Farmer/Customer Deletion Issues
-- This addresses the role constraint violation error

-- OPTION 1: Fix the role constraint (Recommended if you have database admin access)
-- Drop the existing role check constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Create new constraint that includes inactive roles
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN (
    'farmer', 
    'customer', 
    'admin', 
    'inactive_farmer',    -- Allow soft-deleted farmers
    'inactive_customer'   -- Allow soft-deleted customers
));

-- OPTION 2: Alternative approach using is_active field (Fallback solution)
-- Add is_active column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Update existing users to be active by default
UPDATE users 
SET is_active = true 
WHERE is_active IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_role_active ON users(role, is_active);

-- VERIFICATION QUERIES
-- Check current role constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c'
AND conname = 'users_role_check';

-- Check is_active column
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'is_active';

-- Test the deletion system
-- This should now work without constraint violations
SELECT 
    id, 
    name, 
    role, 
    is_active,
    (SELECT COUNT(*) FROM orders WHERE farmer_id = users.id OR customer_id = users.id) as order_count
FROM users 
WHERE name ILIKE '%ramu%' OR name ILIKE '%geetha%';