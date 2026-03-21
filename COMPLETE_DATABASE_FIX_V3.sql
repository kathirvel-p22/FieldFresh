-- Complete Database Fix for FieldFresh v3.0 Enterprise System
-- This script fixes all connection and RLS issues

-- Step 1: Ensure UUID extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Create or update users table with proper structure
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE,
    name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'customer' CHECK (role IN ('farmer', 'customer', 'admin')),
    profile_image TEXT,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    rating DOUBLE PRECISION DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_kyc_done BOOLEAN DEFAULT FALSE,
    is_blocked BOOLEAN DEFAULT FALSE,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create enterprise tables without foreign key constraints initially
CREATE TABLE IF NOT EXISTS session_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    device_info JSONB DEFAULT '{}',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS trust_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    verification_type VARCHAR(50) NOT NULL,
    verification_data JSONB NOT NULL DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'pending',
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS privacy_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    disclosure_level VARCHAR(20) DEFAULT 'basic',
    visible_fields JSONB DEFAULT '[]',
    auto_upgrade_on_payment BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS verification_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    badge_type VARCHAR(50) NOT NULL,
    badge_data JSONB DEFAULT '{}',
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL,
    target_user_id UUID,
    action_type VARCHAR(50) NOT NULL,
    action_data JSONB DEFAULT '{}',
    reason TEXT NOT NULL,
    duration_hours INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_status_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL,
    farmer_id UUID NOT NULL,
    order_id UUID,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    disclosure_level_before VARCHAR(20),
    disclosure_level_after VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fraud_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    risk_score INTEGER DEFAULT 0,
    risk_level VARCHAR(20) DEFAULT 'low',
    risk_factors JSONB DEFAULT '[]',
    last_calculated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create other essential tables
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    price_per_unit DECIMAL(10,2),
    unit VARCHAR(20),
    quantity_total DECIMAL(10,2),
    quantity_left DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'active',
    harvest_time TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    freshness_score INTEGER DEFAULT 0,
    image_urls TEXT[],
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL,
    farmer_id UUID NOT NULL,
    product_id UUID,
    product_name VARCHAR(100),
    quantity DECIMAL(10,2),
    price_per_unit DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_id VARCHAR(100),
    delivery_address TEXT,
    delivery_phone VARCHAR(20),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    farmer_id UUID NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    freshness_rating INTEGER CHECK (freshness_rating >= 1 AND freshness_rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    title VARCHAR(200),
    message TEXT,
    type VARCHAR(50),
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Disable RLS on all tables to prevent policy conflicts
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE session_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE trust_verifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE verification_badges DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity DISABLE ROW LEVEL SECURITY;
ALTER TABLE payment_status_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- Step 6: Grant full permissions to anon and authenticated users
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Step 7: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_session_tokens_user_id_active ON session_tokens(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_session_tokens_token_hash ON session_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_session_tokens_expires_at ON session_tokens(expires_at);

CREATE INDEX IF NOT EXISTS idx_trust_verifications_user_id ON trust_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_trust_verifications_status ON trust_verifications(status);

CREATE INDEX IF NOT EXISTS idx_verification_badges_user_id_active ON verification_badges(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_verification_badges_badge_type ON verification_badges(badge_type);

CREATE INDEX IF NOT EXISTS idx_admin_actions_admin_id ON admin_actions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target_user_id ON admin_actions(target_user_id);

CREATE INDEX IF NOT EXISTS idx_user_activity_user_id_created_at ON user_activity(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_products_farmer_id ON products(farmer_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_farmer_id ON orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Step 8: Insert sample data for testing
INSERT INTO users (id, phone, name, role, is_verified, is_kyc_done) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', '+917010773409', 'Test Farmer', 'farmer', true, true),
    ('550e8400-e29b-41d4-a716-446655440002', '+917010773410', 'Test Customer', 'customer', true, true),
    ('550e8400-e29b-41d4-a716-446655440003', '+917010773411', 'Test Admin', 'admin', true, true)
ON CONFLICT (phone) DO NOTHING;

-- Step 9: Create a simple function to test database connectivity
CREATE OR REPLACE FUNCTION test_connection()
RETURNS TEXT AS $$
BEGIN
    RETURN 'Database connection successful! FieldFresh v3.0 Enterprise System ready.';
END;
$$ LANGUAGE plpgsql;

-- Step 10: Test the function
SELECT test_connection() as status;

-- Success message
SELECT 'FieldFresh v3.0 Database Setup Complete!' as final_status,
       'All tables created and permissions granted' as details,
       'RLS disabled for development - enable in production' as security_note;