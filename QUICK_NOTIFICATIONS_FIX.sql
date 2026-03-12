-- Quick fix for order confirmation error
-- Just add the missing message column if table exists

-- Add message column if it doesn't exist
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS message TEXT;

-- Verify the fix
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;