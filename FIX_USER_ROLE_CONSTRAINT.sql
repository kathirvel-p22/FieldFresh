-- Fix user role constraint to allow inactive roles for soft deletion
-- This will allow the deletion system to work properly

-- First, let's see the current constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c';

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

-- Verify the constraint was updated
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c'
AND conname = 'users_role_check';