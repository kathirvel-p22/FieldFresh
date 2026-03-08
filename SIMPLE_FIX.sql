-- ═══════════════════════════════════════════════════════════════
-- SIMPLE FIX - Run this in Supabase SQL Editor
-- This drops ALL existing policies and creates new permissive ones
-- ═══════════════════════════════════════════════════════════════

-- Step 1: Drop ALL policies on products table
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'products') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON products';
    END LOOP;
END $$;

-- Step 2: Drop ALL policies on orders table
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'orders') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON orders';
    END LOOP;
END $$;

-- Step 3: Drop ALL policies on users table
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON users';
    END LOOP;
END $$;

-- Step 4: Create new permissive policies for products
CREATE POLICY "demo_insert_products" ON products FOR INSERT WITH CHECK (true);
CREATE POLICY "demo_update_products" ON products FOR UPDATE USING (true);
CREATE POLICY "demo_delete_products" ON products FOR DELETE USING (true);
CREATE POLICY "demo_select_products" ON products FOR SELECT USING (true);

-- Step 5: Create new permissive policies for orders
CREATE POLICY "demo_insert_orders" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "demo_update_orders" ON orders FOR UPDATE USING (true);
CREATE POLICY "demo_delete_orders" ON orders FOR DELETE USING (true);
CREATE POLICY "demo_select_orders" ON orders FOR SELECT USING (true);

-- Step 6: Create new permissive policies for users
CREATE POLICY "demo_insert_users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "demo_update_users" ON users FOR UPDATE USING (true);
CREATE POLICY "demo_delete_users" ON users FOR DELETE USING (true);
CREATE POLICY "demo_select_users" ON users FOR SELECT USING (true);

-- Done! All policies are now permissive for demo mode
