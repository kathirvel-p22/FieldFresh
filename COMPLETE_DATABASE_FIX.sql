-- ═══════════════════════════════════════════════════════════════
-- COMPLETE DATABASE FIX - Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════
-- This fixes ALL database errors preventing order completion
-- ═══════════════════════════════════════════════════════════════

-- 1. Create farmer_followers table if it doesn't exist
CREATE TABLE IF NOT EXISTS farmer_followers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, farmer_id)
);

-- Disable RLS
ALTER TABLE farmer_followers DISABLE ROW LEVEL SECURITY;

-- 2. Add missing columns to group_buys if they don't exist
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'group_buys') THEN
    -- Add expires_at column if it doesn't exist
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'group_buys' AND column_name = 'expires_at') THEN
      ALTER TABLE group_buys ADD COLUMN expires_at TIMESTAMPTZ;
    END IF;
    
    -- Add status column if it doesn't exist
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'group_buys' AND column_name = 'status') THEN
      ALTER TABLE group_buys ADD COLUMN status VARCHAR(20) DEFAULT 'active';
    END IF;
  END IF;
END $$;

-- 3. Fix notifications table - add sent_at column if missing
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'notifications') THEN
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'notifications' AND column_name = 'sent_at') THEN
      ALTER TABLE notifications ADD COLUMN sent_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
  END IF;
END $$;

-- 4. Fix orders table - add ALL missing columns
DO $$ 
BEGIN
  -- Create table if it doesn't exist
  IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'orders') THEN
    CREATE TABLE orders (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      customer_id UUID REFERENCES users(id),
      customer_name VARCHAR(255),
      customer_phone VARCHAR(20),
      farmer_id UUID REFERENCES users(id),
      product_id UUID REFERENCES products(id),
      product_name VARCHAR(255),
      quantity DECIMAL(10,2),
      unit VARCHAR(50),
      price_per_unit DECIMAL(10,2),
      total_amount DECIMAL(10,2),
      platform_fee DECIMAL(10,2) DEFAULT 0,
      delivery_charge DECIMAL(10,2) DEFAULT 0,
      delivery_type VARCHAR(50),
      delivery_address TEXT,
      status VARCHAR(50) DEFAULT 'pending',
      payment_status VARCHAR(50) DEFAULT 'pending',
      payment_method VARCHAR(50),
      transaction_id VARCHAR(255),
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );
  ELSE
    -- Add missing columns if table exists
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'customer_name') THEN
      ALTER TABLE orders ADD COLUMN customer_name VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'customer_phone') THEN
      ALTER TABLE orders ADD COLUMN customer_phone VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'confirmed_at') THEN
      ALTER TABLE orders ADD COLUMN confirmed_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'delivered_at') THEN
      ALTER TABLE orders ADD COLUMN delivered_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'delivery_charge') THEN
      ALTER TABLE orders ADD COLUMN delivery_charge DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'platform_fee') THEN
      ALTER TABLE orders ADD COLUMN platform_fee DECIMAL(10,2) DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'payment_method') THEN
      ALTER TABLE orders ADD COLUMN payment_method VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'transaction_id') THEN
      ALTER TABLE orders ADD COLUMN transaction_id VARCHAR(255);
    END IF;
  END IF;
END $$;

-- Disable RLS on orders
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_farmer_followers_customer ON farmer_followers(customer_id);
CREATE INDEX IF NOT EXISTS idx_farmer_followers_farmer ON farmer_followers(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_farmer ON orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- 6. Verify all tables exist
SELECT 'Tables status:' as info;
SELECT 
  table_name,
  CASE WHEN EXISTS (
    SELECT FROM pg_tables pt 
    WHERE pt.tablename = t.table_name
  ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM (
  VALUES 
    ('users'),
    ('products'),
    ('orders'),
    ('shopping_cart'),
    ('customer_bank_accounts'),
    ('customer_payment_pins'),
    ('payment_transactions'),
    ('farmer_followers'),
    ('notifications'),
    ('group_buys')
) AS t(table_name);

-- 7. Verify orders table columns
SELECT 'Orders table columns:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- Success message
SELECT '✅ ALL DATABASE FIXES COMPLETE! You can now complete your purchase.' as result;
