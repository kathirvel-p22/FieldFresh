  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════
-- NOTIFICATIONS TABLE
-- ═══════════════════════════════
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id) ON DELETE SET NULL,
  title       TEXT NOT NULL,
  body        TEXT,
  type        VARCHAR(30) DEFAULT 'harvest_blast',
  is_read     BOOLEAN DEFAULT false,
  sent_at     TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id);

-- ═══════════════════════════════
-- GROUP BUYS TABLE
-- ═══════════════════════════════
CREATE TABLE group_buys (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID REFERENCES products(id),
  creator_id    UUID REFERENCES users(id),
  target_count  INTEGER NOT NULL DEFAULT 5,
  joined_count  INTEGER DEFAULT 1,
  discount_pct  INTEGER DEFAULT 15,
  status        VARCHAR(20) DEFAULT 'open',
  expires_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE group_buy_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID REFERENCES group_buys(id),
  user_id     UUID REFERENCES users(id),
  quantity    DECIMAL(10,2),
  joined_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════
-- AUTO-EXPIRE PRODUCTS (cron job)
-- ═══════════════════════════════
CREATE OR REPLACE FUNCTION expire_old_products()
RETURNS void LANGUAGE SQL AS $$
  UPDATE products SET status = 'expired'
  WHERE status = 'active' AND valid_until < NOW();
$$;

-- ═══════════════════════════════
-- NEARBY CUSTOMERS FUNCTION (PostGIS)
-- ═══════════════════════════════
CREATE OR REPLACE FUNCTION get_nearby_customers(lat FLOAT, lng FLOAT, radius_km FLOAT)
RETURNS TABLE(user_id UUID, fcm_token TEXT)
LANGUAGE SQL AS $$
  SELECT id, fcm_token FROM users
  WHERE role = 'customer'
    AND fcm_token IS NOT NULL
    AND latitude IS NOT NULL AND longitude IS NOT NULL
    AND sqrt(power(latitude - lat, 2) + power(longitude - lng, 2)) * 111 < radius_km;
$$;

-- ═══════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmer_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Anyone can view active products" ON products FOR SELECT USING (status = 'active');
CREATE POLICY "Farmers can insert products" ON products FOR INSERT WITH CHECK (auth.uid() = farmer_id);
CREATE POLICY "Farmers can update own products" ON products FOR UPDATE USING (auth.uid() = farmer_id);

CREATE POLICY "Customers see own orders" ON orders FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = farmer_id);
CREATE POLICY "Customers can place orders" ON orders FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Farmers/customers can update orders" ON orders FOR UPDATE USING (auth.uid() = farmer_id OR auth.uid() = customer_id);

CREATE POLICY "Users see own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can mark read" ON notifications FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Farmers see own wallet" ON farmer_wallets FOR ALL USING (auth.uid() = farmer_id);

-- ═══════════════════════════════
-- SAMPLE DATA
-- ═══════════════════════════════
INSERT INTO users (id, phone, name, role, latitude, longitude, address, is_verified, is_kyc_done, rating) VALUES
  ('11111111-1111-1111-1111-111111111111', '+919876543210', 'Ramu Farmer', 'farmer', 11.0168, 76.9558, 'Coimbatore Farm', true, true, 4.8),
  ('22222222-2222-2222-2222-222222222222', '+919876543211', 'Gopi Organic Farm', 'farmer', 11.0300, 76.9700, 'Pollachi Farm', true, true, 4.6),
  ('33333333-3333-3333-3333-333333333333', '+919876543212', 'Priya Customer', 'customer', 11.0200, 76.9600, 'RS Puram, Coimbatore', true, true, 5.0);

INSERT INTO products (farmer_id, name, category, description, price_per_unit, unit, quantity_total, quantity_left, image_urls, harvest_time, valid_until, freshness_score, latitude, longitude, farm_address) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Fresh Tomatoes', 'vegetables', 'Freshly harvested country tomatoes, no pesticides', 45, 'kg', 50, 48, ARRAY['https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400'], NOW() - INTERVAL '2 hours', NOW() + INTERVAL '10 hours', 88, 11.0168, 76.9558, 'Ramu Farm, Coimbatore'),
  ('11111111-1111-1111-1111-111111111111', 'Organic Spinach', 'leafy', 'Farm-fresh organic spinach bunches', 30, 'bunch', 30, 25, ARRAY['https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400'], NOW() - INTERVAL '1 hour', NOW() + INTERVAL '5 hours', 94, 11.0168, 76.9558, 'Ramu Farm, Coimbatore'),
  ('22222222-2222-2222-2222-222222222222', 'Alphonso Mangoes', 'fruits', 'Sweet Alphonso mangoes from our 20-year old trees', 120, 'kg', 25, 20, ARRAY['https://images.unsplash.com/photo-1553279768-865429fa0078?w=400'], NOW() - INTERVAL '3 hours', NOW() + INTERVAL '21 hours', 82, 11.0300, 76.9700, 'Gopi Orchard, Pollachi'),
  ('22222222-2222-2222-2222-222222222222', 'Country Eggs', 'dairy', 'Country chicken eggs — 30 per tray', 180, 'tray', 20, 18, ARRAY['https://images.unsplash.com/photo-1587486913049-53fc88980cfc?w=400'], NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '7 hours', 97, 11.0300, 76.9700, 'Gopi Farm, Pollachi'),
  ('11111111-1111-1111-1111-111111111111', 'Fresh Carrots', 'roots', 'Crunchy farm-fresh carrots dug today', 35, 'kg', 40, 38, ARRAY['https://images.unsplash.com/photo-1445282768818-728615cc910a?w=400'], NOW() - INTERVAL '4 hours', NOW() + INTERVAL '44 hours', 79, 11.0168, 76.9558, 'Ramu Farm, Coimbatore'),
  ('11111111-1111-1111-1111-111111111111', 'Fresh Coriander', 'herbs', 'Fragrant fresh coriander bunches', 15, 'bunch', 60, 55, ARRAY['https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400'], NOW() - INTERVAL '45 minutes', NOW() + INTERVAL '5 hours', 96, 11.0168, 76.9558, 'Ramu Farm, Coimbatore');

INSERT INTO farmer_wallets (farmer_id, balance, total_earned, this_month, order_count) VALUES
  ('11111111-1111-1111-1111-111111111111', 4850.00, 28400.00, 8200.00, 47),
  ('22222222-2222-2222-2222-222222222222', 2100.00, 15600.00, 4900.00, 31);
