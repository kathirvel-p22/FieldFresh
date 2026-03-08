-- ============================================
-- FINAL COMPLETE SETUP - Run this in Supabase
-- ============================================
-- This includes: Location fields + Payment system + Data fixes

-- PART 1: Add location columns (if not exists)
-- ============================================
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS village VARCHAR(100),
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS district VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(100);

-- PART 2: Update ALL users with location data
-- ============================================
UPDATE users
SET 
  village = COALESCE(village, 'Velachery'),
  city = COALESCE(city, 'Chennai'),
  district = COALESCE(district, 'Chennai'),
  state = COALESCE(state, 'Tamil Nadu'),
  latitude = COALESCE(latitude, 13.0827),
  longitude = COALESCE(longitude, 80.2707)
WHERE village IS NULL OR city IS NULL OR district IS NULL OR state IS NULL
   OR latitude IS NULL OR longitude IS NULL;

-- PART 3: Fix products visibility
-- ============================================
UPDATE products
SET 
  status = 'active',
  valid_until = NOW() + INTERVAL '30 days',
  latitude = COALESCE(latitude, 13.0827),
  longitude = COALESCE(longitude, 80.2707),
  quantity_left = GREATEST(quantity_left, 100)
WHERE TRUE;

-- PART 4: Create payment system tables
-- ============================================

-- Customer Bank Accounts
CREATE TABLE IF NOT EXISTS customer_bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  account_holder_name VARCHAR(100) NOT NULL,
  account_number VARCHAR(20) NOT NULL,
  ifsc_code VARCHAR(11) NOT NULL,
  bank_name VARCHAR(100) NOT NULL,
  account_type VARCHAR(20) DEFAULT 'savings',
  is_verified BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  balance DECIMAL(10, 2) DEFAULT 5000.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, account_number)
);

-- Payment PINs
CREATE TABLE IF NOT EXISTS customer_payment_pins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  pin_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shopping Cart
CREATE TABLE IF NOT EXISTS shopping_cart (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity DECIMAL(10, 2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  price_per_unit DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, product_id)
);

-- Payment Transactions
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES users(id),
  farmer_id UUID REFERENCES users(id),
  bank_account_id UUID REFERENCES customer_bank_accounts(id),
  amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(50) DEFAULT 'bank_account',
  transaction_status VARCHAR(20) DEFAULT 'pending',
  transaction_id VARCHAR(100) UNIQUE,
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PART 5: Create indexes
-- ============================================
CREATE INDEX IF NOT EXISTS idx_bank_accounts_customer ON customer_bank_accounts(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_customer ON shopping_cart(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_product ON shopping_cart(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_customer ON payment_transactions(customer_id);

-- PART 6: Add payment fields to orders
-- ============================================
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'bank_account',
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(100);

-- PART 7: Create demo bank accounts for all customers
-- ============================================
INSERT INTO customer_bank_accounts (
  customer_id,
  account_holder_name,
  account_number,
  ifsc_code,
  bank_name,
  account_type,
  is_verified,
  is_primary,
  balance
) 
SELECT 
  id,
  name,
  '1234567890',
  'SBIN0001234',
  'State Bank of India',
  'savings',
  true,
  true,
  5000.00
FROM users 
WHERE role = 'customer'
ON CONFLICT (customer_id, account_number) DO NOTHING;

-- PART 8: Verification queries
-- ============================================

-- Check users have complete data
SELECT 
  'Users with complete location' as check_name,
  COUNT(*) as total,
  COUNT(CASE WHEN village IS NOT NULL AND city IS NOT NULL 
             AND district IS NOT NULL AND state IS NOT NULL THEN 1 END) as complete
FROM users;

-- Check products are visible
SELECT 
  'Active products' as check_name,
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'active' AND valid_until > NOW() 
             AND quantity_left > 0 THEN 1 END) as visible
FROM products;

-- Check payment tables
SELECT 
  'Bank Accounts' as table_name,
  COUNT(*) as count
FROM customer_bank_accounts
UNION ALL
SELECT 
  'Shopping Cart' as table_name,
  COUNT(*) as count
FROM shopping_cart
UNION ALL
SELECT 
  'Payment Transactions' as table_name,
  COUNT(*) as count
FROM payment_transactions;

-- Show sample user data
SELECT 
  name,
  phone,
  role,
  village,
  city,
  district,
  state,
  is_verified,
  is_kyc_done
FROM users
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- SUCCESS! Complete setup done
-- ============================================
-- Next steps:
-- 1. Run: flutter pub get
-- 2. Hot reload: press 'r' in terminal
-- 3. Test all features
-- ============================================
