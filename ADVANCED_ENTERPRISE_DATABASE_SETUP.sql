-- FieldFresh v3.0 Advanced Enterprise System Database Setup
-- This script creates all the necessary tables and functions for the advanced features

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Trust Verifications Table
CREATE TABLE IF NOT EXISTS trust_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    verification_type VARCHAR(50) NOT NULL CHECK (verification_type IN ('phone', 'profile', 'farm', 'admin', 'reputation', 'government')),
    verification_data JSONB NOT NULL DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'rejected')),
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, verification_type)
);

-- Session Tokens Table
CREATE TABLE IF NOT EXISTS session_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    device_info JSONB DEFAULT '{}',
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for session tokens
CREATE INDEX IF NOT EXISTS idx_session_tokens_user_id_active ON session_tokens(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_session_tokens_token_hash ON session_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_session_tokens_expires_at ON session_tokens(expires_at);

-- Privacy Settings Table
CREATE TABLE IF NOT EXISTS privacy_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    disclosure_level VARCHAR(20) DEFAULT 'basic' CHECK (disclosure_level IN ('basic', 'partial', 'full')),
    visible_fields JSONB DEFAULT '[]',
    auto_upgrade_on_payment BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Verification Badges Table
CREATE TABLE IF NOT EXISTS verification_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL CHECK (badge_type IN ('liveFarmProof', 'recentlyActive', 'fastResponse', 'deliverySuccess', 'repeatBuyer', 'topRated', 'verified', 'newbie', 'experienced', 'reliable')),
    badge_data JSONB DEFAULT '{}',
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for verification badges
CREATE INDEX IF NOT EXISTS idx_verification_badges_user_id_active ON verification_badges(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_verification_badges_badge_type ON verification_badges(badge_type);

-- Admin Actions Table
CREATE TABLE IF NOT EXISTS admin_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('approve', 'reject', 'suspend', 'unsuspend', 'flag', 'unflag', 'delete', 'verifyFarm', 'rejectFarm', 'awardBadge', 'removeBadge', 'updateTrust')),
    action_data JSONB DEFAULT '{}',
    reason TEXT NOT NULL,
    duration_hours INTEGER, -- For suspension actions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for admin actions
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin_id ON admin_actions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target_user_id ON admin_actions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_action_type ON admin_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_admin_actions_created_at ON admin_actions(created_at);

-- User Activity Tracking Table
CREATE TABLE IF NOT EXISTS user_activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    activity_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for user activity
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id_created_at ON user_activity(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_user_activity_activity_type ON user_activity(activity_type);

-- Payment Status Tracking Table
CREATE TABLE IF NOT EXISTS payment_status_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    disclosure_level_granted VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for payment status log
CREATE INDEX IF NOT EXISTS idx_payment_status_log_customer_farmer ON payment_status_log(customer_id, farmer_id);
CREATE INDEX IF NOT EXISTS idx_payment_status_log_order_id ON payment_status_log(order_id);

-- Fraud Scores Table
CREATE TABLE IF NOT EXISTS fraud_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    risk_score DECIMAL(3,2) NOT NULL CHECK (risk_score >= 0 AND risk_score <= 1),
    risk_level VARCHAR(10) NOT NULL CHECK (risk_level IN ('low', 'medium', 'high')),
    reasons TEXT[] DEFAULT '{}',
    flagged_by UUID REFERENCES users(id),
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for fraud scores
CREATE INDEX IF NOT EXISTS idx_fraud_scores_user_id ON fraud_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_scores_risk_level ON fraud_scores(risk_level);

-- Admin Alerts Table
CREATE TABLE IF NOT EXISTS admin_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    data JSONB DEFAULT '{}',
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for admin alerts
CREATE INDEX IF NOT EXISTS idx_admin_alerts_is_read_created_at ON admin_alerts(is_read, created_at);
CREATE INDEX IF NOT EXISTS idx_admin_alerts_priority ON admin_alerts(priority);

-- Add new columns to existing users table if they don't exist
DO $$ 
BEGIN
    -- Add status column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'status') THEN
        ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'flagged', 'deleted', 'pending'));
    END IF;
    
    -- Add suspended_until column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'suspended_until') THEN
        ALTER TABLE users ADD COLUMN suspended_until TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Trust Scores View (Computed)
CREATE OR REPLACE VIEW trust_scores AS
SELECT 
    u.id as user_id,
    u.name,
    u.role,
    COALESCE(
        (CASE WHEN tv_phone.status = 'completed' THEN 10 ELSE 0 END) +
        (CASE WHEN tv_profile.status = 'completed' THEN 15 ELSE 0 END) +
        (CASE WHEN tv_farm.status = 'completed' THEN 20 ELSE 0 END) +
        (CASE WHEN tv_admin.status = 'completed' THEN 25 ELSE 0 END) +
        (CASE WHEN tv_reputation.status = 'completed' THEN 25 ELSE 0 END) +
        (CASE WHEN tv_government.status = 'completed' THEN 5 ELSE 0 END),
        0
    ) as trust_score,
    GREATEST(
        COALESCE(tv_phone.updated_at, u.created_at),
        COALESCE(tv_profile.updated_at, u.created_at),
        COALESCE(tv_farm.updated_at, u.created_at),
        COALESCE(tv_admin.updated_at, u.created_at),
        COALESCE(tv_reputation.updated_at, u.created_at),
        COALESCE(tv_government.updated_at, u.created_at)
    ) as last_updated
FROM users u
LEFT JOIN trust_verifications tv_phone ON u.id = tv_phone.user_id AND tv_phone.verification_type = 'phone'
LEFT JOIN trust_verifications tv_profile ON u.id = tv_profile.user_id AND tv_profile.verification_type = 'profile'
LEFT JOIN trust_verifications tv_farm ON u.id = tv_farm.user_id AND tv_farm.verification_type = 'farm'
LEFT JOIN trust_verifications tv_admin ON u.id = tv_admin.user_id AND tv_admin.verification_type = 'admin'
LEFT JOIN trust_verifications tv_reputation ON u.id = tv_reputation.user_id AND tv_reputation.verification_type = 'reputation'
LEFT JOIN trust_verifications tv_government ON u.id = tv_government.user_id AND tv_government.verification_type = 'government';

-- Function to automatically update trust scores
CREATE OR REPLACE FUNCTION update_trust_score_on_verification()
RETURNS TRIGGER AS $$
BEGIN
    -- Trigger real-time update notification
    PERFORM pg_notify('trust_score_updated', NEW.user_id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for trust score updates
DROP TRIGGER IF EXISTS trust_verification_updated ON trust_verifications;
CREATE TRIGGER trust_verification_updated
    AFTER INSERT OR UPDATE ON trust_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_trust_score_on_verification();

-- Function to clean expired session tokens
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM session_tokens 
    WHERE expires_at < NOW() OR is_active = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Function to update user activity
CREATE OR REPLACE FUNCTION log_user_activity(
    p_user_id UUID,
    p_activity_type VARCHAR(50),
    p_activity_data JSONB DEFAULT '{}'
)
RETURNS void AS $$
BEGIN
    INSERT INTO user_activity (user_id, activity_type, activity_data)
    VALUES (p_user_id, p_activity_type, p_activity_data);
    
    -- Update last activity in users table
    UPDATE users 
    SET updated_at = NOW() 
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to evaluate and award badges
CREATE OR REPLACE FUNCTION evaluate_user_badges(p_user_id UUID)
RETURNS void AS $$
DECLARE
    user_data RECORD;
    recent_uploads INTEGER;
    last_activity TIMESTAMP;
    avg_response_time INTEGER;
    delivery_rate DECIMAL;
    repeat_rate DECIMAL;
BEGIN
    -- Get user data for badge evaluation
    SELECT * INTO user_data FROM users WHERE id = p_user_id;
    
    -- Check for Live Farm Proof badge
    SELECT COUNT(*) INTO recent_uploads
    FROM user_activity 
    WHERE user_id = p_user_id 
    AND activity_type = 'video_upload' 
    AND created_at > NOW() - INTERVAL '7 days';
    
    IF recent_uploads > 0 THEN
        INSERT INTO verification_badges (user_id, badge_type, badge_data)
        VALUES (p_user_id, 'liveFarmProof', jsonb_build_object('uploads', recent_uploads))
        ON CONFLICT (user_id, badge_type) DO UPDATE SET
            badge_data = EXCLUDED.badge_data,
            earned_at = NOW(),
            is_active = TRUE;
    END IF;
    
    -- Check for Recently Active badge
    SELECT MAX(created_at) INTO last_activity
    FROM user_activity 
    WHERE user_id = p_user_id;
    
    IF last_activity > NOW() - INTERVAL '5 minutes' THEN
        INSERT INTO verification_badges (user_id, badge_type, badge_data)
        VALUES (p_user_id, 'recentlyActive', jsonb_build_object('last_activity', last_activity))
        ON CONFLICT (user_id, badge_type) DO UPDATE SET
            badge_data = EXCLUDED.badge_data,
            earned_at = NOW(),
            is_active = TRUE;
    END IF;
    
    -- Additional badge evaluations can be added here...
END;
$$ LANGUAGE plpgsql;

-- Function to handle payment status changes and update privacy
CREATE OR REPLACE FUNCTION handle_payment_status_change()
RETURNS TRIGGER AS $$
DECLARE
    disclosure_level VARCHAR(20);
BEGIN
    -- Determine disclosure level based on payment status
    CASE NEW.status
        WHEN 'advance_paid' THEN disclosure_level := 'partial';
        WHEN 'confirmed' THEN disclosure_level := 'full';
        ELSE disclosure_level := 'basic';
    END CASE;
    
    -- Log the payment status change
    INSERT INTO payment_status_log (order_id, customer_id, farmer_id, old_status, new_status, disclosure_level_granted)
    VALUES (NEW.id, NEW.customer_id, NEW.farmer_id, OLD.status, NEW.status, disclosure_level);
    
    -- Notify about disclosure upgrade if applicable
    IF disclosure_level != 'basic' THEN
        INSERT INTO notifications (user_id, title, message, type, data)
        VALUES (
            NEW.customer_id,
            'New Information Unlocked',
            CASE 
                WHEN disclosure_level = 'partial' THEN 'You can now view the farmer''s phone number and approximate location.'
                WHEN disclosure_level = 'full' THEN 'You now have access to complete farm details and contact information.'
            END,
            'privacy_upgrade',
            jsonb_build_object('farmer_id', NEW.farmer_id, 'disclosure_level', disclosure_level)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for payment status changes
DROP TRIGGER IF EXISTS payment_status_change_trigger ON orders;
CREATE TRIGGER payment_status_change_trigger
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION handle_payment_status_change();

-- Function to auto-verify phone verification after OTP success
CREATE OR REPLACE FUNCTION auto_verify_phone(p_user_id UUID, p_phone_number VARCHAR)
RETURNS void AS $$
BEGIN
    INSERT INTO trust_verifications (user_id, verification_type, verification_data, status, verified_at)
    VALUES (
        p_user_id,
        'phone',
        jsonb_build_object('phone_number', p_phone_number, 'verified_at', NOW(), 'method', 'otp'),
        'completed',
        NOW()
    )
    ON CONFLICT (user_id, verification_type) DO UPDATE SET
        verification_data = EXCLUDED.verification_data,
        status = 'completed',
        verified_at = NOW(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to auto-verify profile completion
CREATE OR REPLACE FUNCTION auto_verify_profile(p_user_id UUID)
RETURNS void AS $$
DECLARE
    user_data RECORD;
    profile_complete BOOLEAN := TRUE;
BEGIN
    -- Get user data
    SELECT * INTO user_data FROM users WHERE id = p_user_id;
    
    -- Check if profile is complete
    IF user_data.name IS NULL OR user_data.name = '' THEN profile_complete := FALSE; END IF;
    IF user_data.profile_image IS NULL OR user_data.profile_image = '' THEN profile_complete := FALSE; END IF;
    IF user_data.address IS NULL OR user_data.address = '' THEN profile_complete := FALSE; END IF;
    
    -- If profile is complete, add verification
    IF profile_complete THEN
        INSERT INTO trust_verifications (user_id, verification_type, verification_data, status, verified_at)
        VALUES (
            p_user_id,
            'profile',
            jsonb_build_object('profile_completeness', 100, 'verified_fields', ARRAY['name', 'profile_image', 'address'], 'auto_verified', true),
            'completed',
            NOW()
        )
        ON CONFLICT (user_id, verification_type) DO UPDATE SET
            verification_data = EXCLUDED.verification_data,
            status = 'completed',
            verified_at = NOW(),
            updated_at = NOW();
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create RLS (Row Level Security) policies for the new tables
ALTER TABLE trust_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_status_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_alerts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for trust_verifications
CREATE POLICY "Users can view their own verifications" ON trust_verifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all verifications" ON trust_verifications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Users can insert their own verifications" ON trust_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update verifications" ON trust_verifications
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for session_tokens
CREATE POLICY "Users can manage their own session tokens" ON session_tokens
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for privacy_settings
CREATE POLICY "Users can manage their own privacy settings" ON privacy_settings
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for verification_badges
CREATE POLICY "Users can view their own badges" ON verification_badges
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Public can view active badges" ON verification_badges
    FOR SELECT USING (is_active = true);

CREATE POLICY "System can manage badges" ON verification_badges
    FOR ALL USING (true); -- This will be restricted by application logic

-- RLS Policies for admin_actions
CREATE POLICY "Admins can view all admin actions" ON admin_actions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can insert admin actions" ON admin_actions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        ) AND auth.uid() = admin_id
    );

-- RLS Policies for user_activity
CREATE POLICY "Users can view their own activity" ON user_activity
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can log user activity" ON user_activity
    FOR INSERT WITH CHECK (true); -- Restricted by application logic

-- RLS Policies for admin_alerts
CREATE POLICY "Admins can view all alerts" ON admin_alerts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Insert initial data for existing users
-- Auto-verify phone for users who already have phone numbers
INSERT INTO trust_verifications (user_id, verification_type, verification_data, status, verified_at)
SELECT 
    id,
    'phone',
    jsonb_build_object('phone_number', phone, 'auto_verified', true),
    'completed',
    NOW()
FROM users 
WHERE phone IS NOT NULL AND phone != ''
ON CONFLICT (user_id, verification_type) DO NOTHING;

-- Auto-verify profile for users who have complete profiles
INSERT INTO trust_verifications (user_id, verification_type, verification_data, status, verified_at)
SELECT 
    id,
    'profile',
    jsonb_build_object('profile_completeness', 100, 'auto_verified', true),
    'completed',
    NOW()
FROM users 
WHERE name IS NOT NULL AND name != '' 
    AND profile_image IS NOT NULL AND profile_image != ''
    AND address IS NOT NULL AND address != ''
ON CONFLICT (user_id, verification_type) DO NOTHING;

-- Create default privacy settings for all existing users
INSERT INTO privacy_settings (user_id, disclosure_level, visible_fields, auto_upgrade_on_payment)
SELECT 
    id,
    'basic',
    '["name", "district", "rating", "trust_score", "profile_image", "role", "created_at"]'::jsonb,
    true
FROM users
ON CONFLICT (user_id) DO NOTHING;

-- Create a scheduled job to clean up expired tokens (if pg_cron is available)
-- SELECT cron.schedule('cleanup-expired-tokens', '0 */6 * * *', 'SELECT cleanup_expired_tokens();');

COMMIT;