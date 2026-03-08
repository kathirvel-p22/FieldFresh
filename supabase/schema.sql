-- ═══════════════════════════════════════════════════════════════
-- FIELDFRESH — SUPABASE DATABASE SCHEMA
-- Run this entire file in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste → Run
-- ═══════════════════════════════════════════════════════════════

-- Enable PostGIS for geo queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ── USERS TABLE ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         VARCHAR(20) UNIQUE NOT NULL,
  name          VARCHAR(100),
  role          VARCHAR(20) CHECK (role IN ('farmer', 'customer', 'delivery', 'admin')) DEFAULT 'customer',
  avatar_url    TEXT,
  profile_image TEXT,
  address       TEXT,
  language      VARCHAR(20) DEFAULT 'en',
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  radius_km     INTEGER DEFAULT 25,
  fcm_token     TEXT,
  is_verified   BOOLEAN DEFAULT false,
  is_kyc_done   BOOLEAN DEFAULT false,
  rating        DECIMAL(3,2) DEFAULT 5.0,
  total_orders  INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── PRODUCTS TABLE ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_name     VARCHAR(100),
  name            VARCHAR(100) NOT NULL,
  category        VARCHAR(50) DEFAULT 'Vegetables',
  description     TEXT,
  price_per_unit  DECIMAL(10,2) NOT NULL,
  unit            VARCHAR(20) DEFAULT 'kg',
  quantity_total  DECIMAL(10,2) NOT NULL,
  quantity_left   DECIMAL(10,2) NOT NULL,
  image_urls      TEXT[] DEFAULT '{}',
  harvest_time    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until     TIMESTAMPTZ NOT NULL,
  freshness_score INTEGER DEFAULT 100,
  latitude        DOUBLE PRECISION NOT NULL DEFAULT 13.0827,
  longitude       DOUBLE PRECISION NOT NULL DEFAULT 80.2707,
  farmer_address  TEXT,
  status          VARCHAR(20) DEFAULT 'active',
  total_orders    INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast geo queries
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_valid_until ON products(valid_until);
CREATE INDEX IF NOT EXISTS idx_products_farmer_id ON products(farmer_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- ── ORDERS TABLE ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id         UUID REFERENCES users(id),
  customer_name       VARCHAR(100),
  customer_phone      VARCHAR(20),
  farmer_id           UUID REFERENCES users(id),
  farmer_name         VARCHAR(100),
  product_id          UUID REFERENCES products(id),
  product_name        VARCHAR(100),
  product_image       TEXT,
  quantity            DECIMAL(10,2) NOT NULL,
  unit                VARCHAR(20),
  price_per_unit      DECIMAL(10,2),
  total_amount        DECIMAL(10,2) NOT NULL,
  delivery_type       VARCHAR(20) DEFAULT 'delivery',
  delivery_address    TEXT,
  status              VARCHAR(30) DEFAULT 'pending',
  payment_status      VARCHAR(20) DEFAULT 'pending',
  razorpay_order_id   TEXT,
  razorpay_payment_id TEXT,
  rating              DECIMAL(3,2),
  review              TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_farmer_id ON orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- ── FARMER WALLETS TABLE ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS farmer_wallets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id     UUID REFERENCES users(id) UNIQUE,
  balance       DECIMAL(12,2) DEFAULT 0,
  total_earned  DECIMAL(12,2) DEFAULT 0,
  upi_id        VARCHAR(100),
  bank_account  VARCHAR(50),
  bank_ifsc     VARCHAR(20),
  bank_name     VARCHAR(100),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── WALLET TRANSACTIONS TABLE ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id   UUID REFERENCES users(id),
  amount      DECIMAL(10,2),
  type        VARCHAR(10) CHECK (type IN ('credit', 'debit')),
  description TEXT,
  order_id    UUID REFERENCES orders(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── NOTIFICATIONS TABLE ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id),
  product_id  UUID REFERENCES products(id),
  order_id    UUID REFERENCES orders(id),
  title       TEXT,
  body        TEXT,
  type        VARCHAR(30) DEFAULT 'system',
  is_read     BOOLEAN DEFAULT false,
  data        JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- ── GROUP BUYING TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_buys (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID REFERENCES products(id),
  organizer_id  UUID REFERENCES users(id),
  title         TEXT,
  target_qty    DECIMAL(10,2),
  current_qty   DECIMAL(10,2) DEFAULT 0,
  discount_pct  INTEGER DEFAULT 15,
  status        VARCHAR(20) DEFAULT 'open',
  deadline      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS group_buy_members (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_buy_id UUID REFERENCES group_buys(id),
  user_id      UUID REFERENCES users(id),
  quantity     DECIMAL(10,2),
  joined_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── FARMER FOLLOWERS TABLE ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS farmer_followers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id  UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, farmer_id)
);

CREATE INDEX IF NOT EXISTS idx_farmer_followers_customer ON farmer_followers(customer_id);
CREATE INDEX IF NOT EXISTS idx_farmer_followers_farmer ON farmer_followers(farmer_id);

-- ── ADVANCE PAYMENTS TABLE ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS advance_payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  farmer_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id      UUID REFERENCES products(id) ON DELETE SET NULL,
  advance_amount  DECIMAL(10,2) NOT NULL,
  total_amount    DECIMAL(10,2) NOT NULL,
  payment_status  VARCHAR(20) DEFAULT 'pending',
  payment_method  VARCHAR(50),
  payment_id      TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_advance_payments_customer ON advance_payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_advance_payments_farmer ON advance_payments(farmer_id);

-- Add location fields to users table if not exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS district VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS village VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(100);

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY POLICIES
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmer_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users: anyone can read basic info, only self can update
CREATE POLICY "Users are publicly readable"
  ON users FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Products: public read, farmer can manage own
CREATE POLICY "Products are publicly readable"
  ON products FOR SELECT USING (true);

CREATE POLICY "Farmers can insert products"
  ON products FOR INSERT WITH CHECK (auth.uid() = farmer_id);

CREATE POLICY "Farmers can update own products"
  ON products FOR UPDATE USING (auth.uid() = farmer_id);

CREATE POLICY "Farmers can delete own products"
  ON products FOR DELETE USING (auth.uid() = farmer_id);

-- Orders: customers and farmers can read own orders
CREATE POLICY "Customers can read own orders"
  ON orders FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = farmer_id);

CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Farmers can update order status"
  ON orders FOR UPDATE USING (auth.uid() = farmer_id OR auth.uid() = customer_id);

-- Notifications: users can read own notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT WITH CHECK (true);

-- Wallets: only farmer can read own wallet
CREATE POLICY "Farmers can read own wallet"
  ON farmer_wallets FOR SELECT USING (auth.uid() = farmer_id);

-- ═══════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

-- Get nearby customers within radius (for Harvest Blast)
CREATE OR REPLACE FUNCTION get_nearby_customer_tokens(
  farm_lat FLOAT,
  farm_lng FLOAT,
  radius_km FLOAT DEFAULT 25
)
RETURNS TABLE(user_id UUID, fcm_token TEXT)
LANGUAGE SQL AS $$
  SELECT id, fcm_token
  FROM users
  WHERE role = 'customer'
    AND fcm_token IS NOT NULL
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
    AND (
      6371 * acos(
        cos(radians(farm_lat)) * cos(radians(latitude)) *
        cos(radians(longitude) - radians(farm_lng)) +
        sin(radians(farm_lat)) * sin(radians(latitude))
      )
    ) <= radius_km;
$$;

-- Auto-expire products function
CREATE OR REPLACE FUNCTION expire_old_products()
RETURNS void
LANGUAGE SQL AS $$
  UPDATE products
  SET status = 'expired'
  WHERE status = 'active'
    AND valid_until < NOW();
$$;

-- Update wallet on order delivery
CREATE OR REPLACE FUNCTION update_farmer_wallet()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    -- Credit 95% of order amount to farmer wallet
    INSERT INTO farmer_wallets (farmer_id, balance, total_earned)
    VALUES (NEW.farmer_id, NEW.total_amount * 0.95, NEW.total_amount * 0.95)
    ON CONFLICT (farmer_id) DO UPDATE
    SET balance = farmer_wallets.balance + NEW.total_amount * 0.95,
        total_earned = farmer_wallets.total_earned + NEW.total_amount * 0.95,
        updated_at = NOW();

    -- Log transaction
    INSERT INTO wallet_transactions (farmer_id, amount, type, description, order_id)
    VALUES (NEW.farmer_id, NEW.total_amount * 0.95, 'credit',
            'Payment for ' || NEW.product_name, NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_farmer_wallet
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_farmer_wallet();

-- ═══════════════════════════════════════════════════════════════
-- REALTIME — Enable for live order updates
-- ═══════════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ═══════════════════════════════════════════════════════════════
-- STORAGE BUCKETS
-- ═══════════════════════════════════════════════════════════════
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('farmer-avatars', 'farmer-avatars', true)
ON CONFLICT DO NOTHING;

CREATE POLICY "Product images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

-- ═══════════════════════════════════════════════════════════════
-- SEED DATA — Sample farmers and products for testing
-- ═══════════════════════════════════════════════════════════════

INSERT INTO users (id, phone, name, role, latitude, longitude, is_verified, is_kyc_done, rating, created_at) VALUES
  ('11111111-1111-1111-1111-111111111111', '+919876543210', 'Ramu Farmer', 'farmer', 13.0827, 80.2707, true, true, 4.8, NOW()),
  ('22222222-2222-2222-2222-222222222222', '+919876543211', 'Geetha Devi', 'farmer', 13.0927, 80.2807, true, true, 4.6, NOW()),
  ('33333333-3333-3333-3333-333333333333', '+919876543212', 'Muthu Kumar', 'farmer', 13.0727, 80.2607, true, true, 4.9, NOW())
ON CONFLICT DO NOTHING;

INSERT INTO products (
  farmer_id, farmer_name, name, category, description,
  price_per_unit, unit, quantity_total, quantity_left,
  harvest_time, valid_until, freshness_score,
  latitude, longitude, status
) VALUES
  (
    '11111111-1111-1111-1111-111111111111', 'Ramu Farmer',
    'Fresh Tomatoes', 'Vegetables',
    'Organically grown red tomatoes, harvested this morning from our 2-acre farm.',
    45, 'kg', 100, 85,
    NOW() - INTERVAL '2 hours', NOW() + INTERVAL '10 hours', 88,
    13.0827, 80.2707, 'active'
  ),
  (
    '22222222-2222-2222-2222-222222222222', 'Geetha Devi',
    'Baby Spinach', 'Leafy Greens',
    'Tender baby spinach leaves, freshly cut. Perfect for salads and cooking.',
    60, 'kg', 30, 25,
    NOW() - INTERVAL '1 hour', NOW() + INTERVAL '5 hours', 95,
    13.0927, 80.2807, 'active'
  ),
  (
    '33333333-3333-3333-3333-333333333333', 'Muthu Kumar',
    'Organic Mangoes', 'Fruits',
    'Sweet Alphonso mangoes from 20-year-old trees. No chemicals used.',
    180, 'kg', 50, 40,
    NOW() - INTERVAL '3 hours', NOW() + INTERVAL '21 hours', 82,
    13.0727, 80.2607, 'active'
  ),
  (
    '11111111-1111-1111-1111-111111111111', 'Ramu Farmer',
    'Fresh Coconuts', 'Fruits',
    'Tender coconuts for drinking. Plucked fresh today morning.',
    25, 'piece', 200, 180,
    NOW() - INTERVAL '4 hours', NOW() + INTERVAL '20 hours', 79,
    13.0827, 80.2707, 'active'
  ),
  (
    '22222222-2222-2222-2222-222222222222', 'Geetha Devi',
    'Drumstick (Moringa)', 'Vegetables',
    'Fresh drumstick sticks from our farm. Great for sambar and curries.',
    35, 'bunch', 60, 55,
    NOW() - INTERVAL '1 hour', NOW() + INTERVAL '11 hours', 93,
    13.0927, 80.2807, 'active'
  )
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════
-- ADMIN USER — Hidden admin for platform management
-- ═══════════════════════════════════════════════════════════════
-- Phone: +919999999999 | Admin Code: admin123
INSERT INTO users (id, phone, name, role, is_verified, is_kyc_done, rating, created_at) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '+919999999999', 'Admin', 'admin', true, true, 5.0, NOW())
ON CONFLICT DO NOTHING;


-- ── PAYMENT SETTINGS TABLE ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payment_settings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id       UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  payment_method  VARCHAR(20) DEFAULT 'upi',
  upi_id          VARCHAR(100),
  account_name    VARCHAR(100),
  account_number  VARCHAR(20),
  ifsc_code       VARCHAR(11),
  bank_name       VARCHAR(100),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_settings_farmer ON payment_settings(farmer_id);
