-- ═══════════════════════════════════════════════════════════════
-- FIX DATABASE ERRORS
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- Fix 1: Add missing district columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS district VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS village VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(100);

-- Fix 2: Fix group_buys foreign key relationship
-- Drop existing table if it has wrong foreign key
DROP TABLE IF EXISTS group_buy_members CASCADE;
DROP TABLE IF EXISTS group_buys CASCADE;

-- Recreate group_buys table with correct foreign key name
CREATE TABLE group_buys (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID REFERENCES products(id) ON DELETE CASCADE,
  creator_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  title         TEXT,
  target_qty    DECIMAL(10,2),
  current_qty   DECIMAL(10,2) DEFAULT 0,
  discount_pct  INTEGER DEFAULT 15,
  status        VARCHAR(20) DEFAULT 'open',
  deadline      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Create group_buy_members table
CREATE TABLE group_buy_members (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_buy_id UUID REFERENCES group_buys(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  quantity     DECIMAL(10,2),
  joined_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_group_buys_creator ON group_buys(creator_id);
CREATE INDEX IF NOT EXISTS idx_group_buys_product ON group_buys(product_id);
CREATE INDEX IF NOT EXISTS idx_group_buys_status ON group_buys(status);
CREATE INDEX IF NOT EXISTS idx_group_buy_members_group ON group_buy_members(group_buy_id);
CREATE INDEX IF NOT EXISTS idx_group_buy_members_user ON group_buy_members(user_id);

-- Disable RLS for group buy tables (demo mode)
ALTER TABLE group_buys DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_buy_members DISABLE ROW LEVEL SECURITY;

-- Verify the fixes
SELECT 'Users columns:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('district', 'city', 'village', 'state');

SELECT 'Group buys foreign keys:' as info;
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'group_buys';
