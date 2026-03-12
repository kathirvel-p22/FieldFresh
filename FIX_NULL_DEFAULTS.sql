-- Fix NULL defaults for required fields
-- Run this in Supabase SQL Editor

-- Set proper default values for required fields
ALTER TABLE products 
ALTER COLUMN price_per_unit SET DEFAULT 0;

ALTER TABLE products 
ALTER COLUMN quantity_total SET DEFAULT 0;

ALTER TABLE products 
ALTER COLUMN quantity_left SET DEFAULT 0;

ALTER TABLE products 
ALTER COLUMN valid_until SET DEFAULT NOW() + INTERVAL '12 hours';

-- Update any existing NULL records (separate statements)
UPDATE products SET price_per_unit = 0 WHERE price_per_unit IS NULL;

UPDATE products SET quantity_total = 0 WHERE quantity_total IS NULL;

UPDATE products SET quantity_left = 0 WHERE quantity_left IS NULL;

UPDATE products SET valid_until = NOW() + INTERVAL '12 hours' WHERE valid_until IS NULL;

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('price_per_unit', 'quantity_total', 'quantity_left', 'valid_until')
ORDER BY column_name;