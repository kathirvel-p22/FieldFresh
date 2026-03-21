-- STEP-BY-STEP FIX for Role Constraint Issue
-- Run these commands ONE BY ONE in Supabase SQL Editor

-- STEP 1: Check what roles currently exist in the database
SELECT DISTINCT role, COUNT(*) as count 
FROM users 
GROUP BY role 
ORDER BY role;

-- STEP 2: Check the current constraint definition
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c'
AND conname = 'users_role_check';

-- STEP 3: Fix any invalid roles first (if any exist)
-- Update any invalid roles to valid ones
UPDATE users 
SET role = 'farmer' 
WHERE role NOT IN ('farmer', 'customer', 'admin');

-- STEP 4: Now drop the constraint safely
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- STEP 5: Add the new constraint with inactive roles allowed
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN (
    'farmer', 
    'customer', 
    'admin', 
    'inactive_farmer',
    'inactive_customer'
));

-- STEP 6: Verify the new constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c'
AND conname = 'users_role_check';