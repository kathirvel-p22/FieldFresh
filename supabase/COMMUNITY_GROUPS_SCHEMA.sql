-- ═══════════════════════════════════════════════════════════════
-- COMMUNITY GROUPS & CHAT - DATABASE SCHEMA
-- Phase 1: Create all required tables
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ── TABLE 1: Group Categories ────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) UNIQUE NOT NULL,
  icon TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLE 2: Community Groups ────────────────────────────────────
CREATE TABLE IF NOT EXISTS community_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES group_categories(id),
  category VARCHAR(50), -- For backward compatibility
  image_url TEXT,
  creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
  member_count INTEGER DEFAULT 1,
  message_count INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLE 3: Group Members ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES community_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'member', -- admin, moderator, member
  is_muted BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- ── TABLE 4: Group Messages ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES community_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  user_name VARCHAR(100), -- Cached for performance
  user_role VARCHAR(20), -- farmer, customer, admin
  message TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text', -- text, image, contact, system
  image_url TEXT,
  metadata JSONB, -- For additional data (contact info, etc.)
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── TABLE 5: Group Invites (Optional) ────────────────────────────
CREATE TABLE IF NOT EXISTS group_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES community_groups(id) ON DELETE CASCADE,
  invited_by UUID REFERENCES users(id) ON DELETE CASCADE,
  invited_user UUID REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, invited_user)
);

-- ═══════════════════════════════════════════════════════════════
-- INDEXES FOR PERFORMANCE
-- ═══════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_community_groups_category ON community_groups(category);
CREATE INDEX IF NOT EXISTS idx_community_groups_creator ON community_groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_community_groups_active ON community_groups(is_active);
CREATE INDEX IF NOT EXISTS idx_community_groups_public ON community_groups(is_public);

CREATE INDEX IF NOT EXISTS idx_group_members_group ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_role ON group_members(role);

CREATE INDEX IF NOT EXISTS idx_group_messages_group ON group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_user ON group_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created ON group_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_messages_type ON group_messages(message_type);

CREATE INDEX IF NOT EXISTS idx_group_invites_group ON group_invites(group_id);
CREATE INDEX IF NOT EXISTS idx_group_invites_user ON group_invites(invited_user);
CREATE INDEX IF NOT EXISTS idx_group_invites_status ON group_invites(status);

-- ═══════════════════════════════════════════════════════════════
-- FUNCTIONS & TRIGGERS
-- ═══════════════════════════════════════════════════════════════

-- Function: Update member count when someone joins/leaves
CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_groups 
    SET member_count = member_count + 1,
        updated_at = NOW()
    WHERE id = NEW.group_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_groups 
    SET member_count = GREATEST(member_count - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.group_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update member count
DROP TRIGGER IF EXISTS trigger_update_member_count ON group_members;
CREATE TRIGGER trigger_update_member_count
AFTER INSERT OR DELETE ON group_members
FOR EACH ROW EXECUTE FUNCTION update_group_member_count();

-- Function: Update message count when message is sent
CREATE OR REPLACE FUNCTION update_group_message_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.is_deleted = false THEN
    UPDATE community_groups 
    SET message_count = message_count + 1,
        updated_at = NOW()
    WHERE id = NEW.group_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.is_deleted = true AND OLD.is_deleted = false THEN
    UPDATE community_groups 
    SET message_count = GREATEST(message_count - 1, 0),
        updated_at = NOW()
    WHERE id = NEW.group_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update message count
DROP TRIGGER IF EXISTS trigger_update_message_count ON group_messages;
CREATE TRIGGER trigger_update_message_count
AFTER INSERT OR UPDATE ON group_messages
FOR EACH ROW EXECUTE FUNCTION update_group_message_count();

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (Disabled for demo mode)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE group_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE community_groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_invites DISABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- SAMPLE DATA
-- ═══════════════════════════════════════════════════════════════

-- Insert categories
INSERT INTO group_categories (name, icon, description) VALUES
('Organic Farming', '🌱', 'Tips and techniques for organic farming'),
('Vegetables', '🥬', 'Vegetable growers community'),
('Fruits', '🍎', 'Fruit farming discussions'),
('Dairy', '🥛', 'Dairy farming and products'),
('Market Tips', '💰', 'Pricing and market strategies'),
('Equipment', '🚜', 'Farming equipment and tools'),
('Seeds', '🌾', 'Seed varieties and suppliers'),
('Pest Control', '🐛', 'Natural pest control methods'),
('Weather', '🌤️', 'Weather updates and farming'),
('Recipes', '🍳', 'Farm-fresh recipes and cooking')
ON CONFLICT (name) DO NOTHING;

-- Insert sample groups
INSERT INTO community_groups (name, description, category, is_public, member_count) VALUES
('Organic Tomato Growers', 'Share tips on growing organic tomatoes without chemicals', 'Vegetables', true, 45),
('Chennai Farmers Network', 'Connect with farmers in Chennai and surrounding areas', 'Market Tips', true, 128),
('Dairy Farming Best Practices', 'Learn about dairy farming, cattle care, and milk production', 'Dairy', true, 67),
('Fresh Fruit Lovers', 'Discuss fruit farming, varieties, and seasonal tips', 'Fruits', true, 89),
('Natural Pest Control', 'Chemical-free pest control methods and solutions', 'Pest Control', true, 34),
('Farm Equipment Exchange', 'Buy, sell, or rent farming equipment', 'Equipment', true, 56),
('Organic Certification Help', 'Get help with organic certification process', 'Organic Farming', true, 23),
('Seasonal Farming Tips', 'Tips for different seasons and crops', 'Market Tips', true, 91),
('Farm-to-Table Recipes', 'Share recipes using fresh farm produce', 'Recipes', true, 112),
('Weather & Farming', 'Weather updates and farming schedules', 'Weather', true, 78)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES
-- ═══════════════════════════════════════════════════════════════

-- Check tables created
SELECT 'Tables created:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('group_categories', 'community_groups', 'group_members', 'group_messages', 'group_invites')
ORDER BY table_name;

-- Check sample data
SELECT 'Sample categories:' as info;
SELECT name, icon FROM group_categories LIMIT 5;

SELECT 'Sample groups:' as info;
SELECT name, category, member_count FROM community_groups LIMIT 5;

-- Check indexes
SELECT 'Indexes created:' as info;
SELECT indexname 
FROM pg_indexes 
WHERE tablename IN ('community_groups', 'group_members', 'group_messages')
ORDER BY tablename, indexname;
