-- ============================================
-- PAYMENT SYSTEM DATABASE SCHEMA
-- ============================================

-- 1. Customer Bank Accounts Table
CREATE TABLE IF NOT EXISTS customer_bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  account_holder_name VARCHAR(100) NOT NULL,
  account_number VARCHAR(20) NOT NULL,
  ifsc_code VARCHAR(11) NOT NULL,
  bank_name VARCHAR(100) NOT NULL,
  account_type VARCHAR(20) DEFAULT 'savings', -- savings, current
  is_verified BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  balance DECIMAL(10, 2) DEFAULT 1000.00, -- Demo balance
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, account_number)
);

-- 2. Customer Payment PINs Table
CREATE TABLE IF NOT EXISTS customer_payment_pins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  pin_hash VARCHAR(255) NOT NULL, -- Hashed PIN for security
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Shopping Cart Table
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

-- 4. Payment Transactions Table
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES users(id),
  farmer_id UUID REFERENCES users(id),
  bank_account_id UUID REFERENCES customer_bank_accounts(id),
  amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(50) DEFAULT 'bank_account', -- bank_account, upi, cod
  transaction_status VARCHAR(20) DEFAULT 'pending', -- pending, success, failed
  transaction_id VARCHAR(100) UNIQUE,
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_bank_accounts_customer ON customer_bank_accounts(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_customer ON shopping_cart(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_product ON shopping_cart(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_customer ON payment_transactions(customer_id);

-- 6. Add payment fields to orders table if not exists
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'bank_account',
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(100);

-- 7. Insert demo bank account for testing
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

-- 8. Verify the setup
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

-- ============================================
-- SUCCESS! Payment system tables created
-- ============================================
