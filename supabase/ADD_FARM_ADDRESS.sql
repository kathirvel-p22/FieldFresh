-- Add farm_address column to products table
-- Run this in your Supabase SQL Editor

ALTER TABLE products 
ADD COLUMN IF NOT EXISTS farm_address TEXT;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name = 'farm_address';
