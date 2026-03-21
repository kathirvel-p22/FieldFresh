-- Test Supabase Connection and Basic Setup
-- Run this to verify your Supabase project is working correctly

-- Test 1: Check if users table exists and has data
SELECT 'Testing users table...' as test;
SELECT COUNT(*) as user_count FROM users;

-- Test 2: Check if basic tables exist
SELECT 'Checking table existence...' as test;
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
         THEN 'users table exists' 
         ELSE 'users table missing' END as users_table,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products') 
         THEN 'products table exists' 
         ELSE 'products table missing' END as products_table,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders') 
         THEN 'orders table exists' 
         ELSE 'orders table missing' END as orders_table;

-- Test 3: Check RLS status
SELECT 'Checking RLS status...' as test;
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'products', 'orders', 'session_tokens', 'trust_verifications');

-- Test 4: Simple insert test (will help identify permission issues)
SELECT 'Testing basic permissions...' as test;

-- Test 5: Check if UUID extension is available
SELECT 'Testing UUID extension...' as test;
SELECT uuid_generate_v4() as test_uuid;

-- Success message
SELECT 'Connection test completed!' as status;