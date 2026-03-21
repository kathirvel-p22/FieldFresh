-- ALTERNATIVE APPROACH: Use is_active field instead of role changes
-- This completely avoids the role constraint issue

-- STEP 1: Add is_active column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- STEP 2: Set all existing users as active
UPDATE users 
SET is_active = true 
WHERE is_active IS NULL;

-- STEP 3: Make is_active NOT NULL with default true
ALTER TABLE users 
ALTER COLUMN is_active SET DEFAULT true,
ALTER COLUMN is_active SET NOT NULL;

-- STEP 4: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_role_active ON users(role, is_active);

-- STEP 5: Verify the column was added correctly
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'is_active';

-- STEP 6: Test query to see active farmers
SELECT id, name, role, is_active 
FROM users 
WHERE role = 'farmer' 
AND is_active = true 
LIMIT 5;