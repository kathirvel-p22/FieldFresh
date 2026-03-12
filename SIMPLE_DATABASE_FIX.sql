-- Simple Database Fix for Product Posting
-- Run this in Supabase SQL Editor to fix the products table

-- First, let's see what columns exist in the products table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

-- Add missing columns to products table if they don't exist
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS price_per_unit DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS quantity_total DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS quantity_left DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS unit VARCHAR(20) DEFAULT 'kg',
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'vegetables',
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS harvest_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS valid_until TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '12 hours',
ADD COLUMN IF NOT EXISTS freshness_score INTEGER DEFAULT 85,
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8),
ADD COLUMN IF NOT EXISTS farm_address TEXT,
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active',
ADD COLUMN IF NOT EXISTS order_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Make sure required columns are NOT NULL
ALTER TABLE products 
ALTER COLUMN price_per_unit SET NOT NULL,
ALTER COLUMN quantity_total SET NOT NULL,
ALTER COLUMN quantity_left SET NOT NULL;

-- Update any existing records to have valid values
UPDATE products SET 
  price_per_unit = COALESCE(price_per_unit, 0),
  quantity_total = COALESCE(quantity_total, 0),
  quantity_left = COALESCE(quantity_left, 0),
  unit = COALESCE(unit, 'kg'),
  category = COALESCE(category, 'vegetables'),
  status = COALESCE(status, 'active'),
  freshness_score = COALESCE(freshness_score, 85),
  order_count = COALESCE(order_count, 0),
  created_at = COALESCE(created_at, NOW()),
  updated_at = COALESCE(updated_at, NOW())
WHERE price_per_unit IS NULL OR quantity_total IS NULL OR quantity_left IS NULL;

-- Show the final table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;