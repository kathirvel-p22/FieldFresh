-- Add is_active field to users table for soft deletion
-- This approach avoids the role constraint issue

-- Add is_active column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Update existing users to be active by default
UPDATE users 
SET is_active = true 
WHERE is_active IS NULL;

-- Add index for better performance on queries
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_role_active ON users(role, is_active);

-- Verify the column was added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'is_active';