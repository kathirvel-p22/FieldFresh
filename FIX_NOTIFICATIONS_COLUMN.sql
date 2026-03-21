-- Fix notifications table column issue
-- The error shows 'sent_at' column doesn't exist, but code expects it

-- Check current notifications table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- Add missing sent_at column if it doesn't exist
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update existing records to have sent_at value
UPDATE notifications 
SET sent_at = created_at 
WHERE sent_at IS NULL;

-- Verify the fix
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND column_name IN ('sent_at', 'created_at');