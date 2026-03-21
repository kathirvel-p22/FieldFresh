-- Verification System Database Setup
-- This creates tables for comprehensive user verification

-- User Verifications Table
CREATE TABLE IF NOT EXISTS user_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    verification_type VARCHAR(50) NOT NULL CHECK (verification_type IN ('phone', 'document', 'location', 'selfie', 'address')),
    document_type VARCHAR(100) NOT NULL, -- 'aadhar', 'pan', 'driving_license', 'passport', 'electricity_bill', etc.
    image_urls TEXT[] DEFAULT '{}',
    extracted_data JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'approved', 'rejected', 'expired')),
    rejection_reason TEXT,
    admin_notes TEXT,
    verified_by UUID,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OTP Verifications Table (for phone verification)
CREATE TABLE IF NOT EXISTS otp_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) NOT NULL,
    otp_code VARCHAR(10) NOT NULL,
    purpose VARCHAR(50) DEFAULT 'phone_verification', -- 'phone_verification', 'password_reset', etc.
    is_verified BOOLEAN DEFAULT FALSE,
    attempts INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verification Requirements Table (defines what's required for each user type)
CREATE TABLE IF NOT EXISTS verification_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_role VARCHAR(20) NOT NULL, -- 'farmer', 'customer', 'admin'
    verification_type VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default verification requirements
INSERT INTO verification_requirements (user_role, verification_type, is_required, description) VALUES
-- Farmer requirements
('farmer', 'phone', TRUE, 'Phone number verification with OTP'),
('farmer', 'document', TRUE, 'Government ID proof (Aadhar, PAN, Driving License)'),
('farmer', 'location', TRUE, 'Farm location verification with photo'),
('farmer', 'selfie', TRUE, 'Selfie with ID document for identity verification'),
('farmer', 'address', TRUE, 'Address proof document'),

-- Customer requirements  
('customer', 'phone', TRUE, 'Phone number verification with OTP'),
('customer', 'document', TRUE, 'Government ID proof (Aadhar, PAN, Driving License)'),
('customer', 'location', FALSE, 'Location verification (optional for customers)'),
('customer', 'selfie', TRUE, 'Selfie with ID document for identity verification'),
('customer', 'address', TRUE, 'Address proof for delivery'),

-- Admin requirements
('admin', 'phone', TRUE, 'Phone number verification with OTP'),
('admin', 'document', TRUE, 'Government ID proof'),
('admin', 'selfie', TRUE, 'Identity verification'),
('admin', 'address', TRUE, 'Address verification')

ON CONFLICT DO NOTHING;

-- Verification Templates Table (for document types and their requirements)
CREATE TABLE IF NOT EXISTS verification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_type VARCHAR(100) NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    required_images INTEGER DEFAULT 1, -- front, back, etc.
    image_requirements JSONB DEFAULT '{}', -- size, format, etc.
    extraction_fields JSONB DEFAULT '{}', -- fields to extract from document
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert document templates
INSERT INTO verification_templates (document_type, display_name, description, required_images, image_requirements, extraction_fields) VALUES
('aadhar', 'Aadhar Card', 'Government issued Aadhar card for identity verification', 2, 
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"name": "string", "aadhar_number": "string", "address": "string", "dob": "date"}'),

('pan', 'PAN Card', 'Permanent Account Number card for identity verification', 1,
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"name": "string", "pan_number": "string", "father_name": "string", "dob": "date"}'),

('driving_license', 'Driving License', 'Government issued driving license', 2,
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"name": "string", "license_number": "string", "address": "string", "dob": "date"}'),

('passport', 'Passport', 'Indian passport for identity verification', 1,
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"name": "string", "passport_number": "string", "address": "string", "dob": "date"}'),

('electricity_bill', 'Electricity Bill', 'Electricity bill for address verification', 1,
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"name": "string", "address": "string", "bill_date": "date", "consumer_number": "string"}'),

('bank_statement', 'Bank Statement', 'Bank statement for address verification', 1,
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"name": "string", "address": "string", "account_number": "string", "statement_date": "date"}'),

('land_document', 'Land Document', 'Land ownership document for farmers', 1,
 '{"formats": ["jpg", "jpeg", "png"], "max_size_mb": 5, "min_resolution": "800x600"}',
 '{"owner_name": "string", "survey_number": "string", "area": "string", "location": "string"}')

ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_verifications_user_id ON user_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_verifications_type_status ON user_verifications(verification_type, status);
CREATE INDEX IF NOT EXISTS idx_user_verifications_status ON user_verifications(status);
CREATE INDEX IF NOT EXISTS idx_otp_verifications_phone ON otp_verifications(phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_verifications_expires ON otp_verifications(expires_at);

-- Add verification status to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'unverified' 
    CHECK (verification_status IN ('unverified', 'partial', 'pending', 'verified', 'rejected'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_progress DECIMAL(3,2) DEFAULT 0.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_verification_update TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Function to update user verification status
CREATE OR REPLACE FUNCTION update_user_verification_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user's verification status based on their verifications
    UPDATE users SET 
        verification_status = CASE 
            WHEN EXISTS (
                SELECT 1 FROM user_verifications 
                WHERE user_id = NEW.user_id 
                AND status = 'rejected'
            ) THEN 'rejected'
            WHEN (
                SELECT COUNT(*) FROM user_verifications 
                WHERE user_id = NEW.user_id 
                AND status = 'approved'
            ) >= 4 THEN 'verified'  -- phone, document, location, selfie
            WHEN EXISTS (
                SELECT 1 FROM user_verifications 
                WHERE user_id = NEW.user_id 
                AND status = 'pending'
            ) THEN 'pending'
            WHEN EXISTS (
                SELECT 1 FROM user_verifications 
                WHERE user_id = NEW.user_id 
                AND status = 'approved'
            ) THEN 'partial'
            ELSE 'unverified'
        END,
        verification_progress = (
            SELECT COALESCE(
                COUNT(*) FILTER (WHERE status = 'approved')::DECIMAL / 4.0,
                0.0
            )
            FROM user_verifications 
            WHERE user_id = NEW.user_id
        ),
        last_verification_update = NOW()
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update user verification status
DROP TRIGGER IF EXISTS trigger_update_user_verification_status ON user_verifications;
CREATE TRIGGER trigger_update_user_verification_status
    AFTER INSERT OR UPDATE ON user_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_user_verification_status();

-- Function to clean up expired OTPs
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
    DELETE FROM otp_verifications 
    WHERE expires_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL ON user_verifications TO anon, authenticated;
GRANT ALL ON otp_verifications TO anon, authenticated;
GRANT ALL ON verification_requirements TO anon, authenticated;
GRANT ALL ON verification_templates TO anon, authenticated;

-- Success message
SELECT 'Verification System Database Setup Complete!' as status,
       'Tables: user_verifications, otp_verifications, verification_requirements, verification_templates' as tables_created,
       'Triggers and functions created for auto-status updates' as additional_features;