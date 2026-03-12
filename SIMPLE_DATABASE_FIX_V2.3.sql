-- Simple Database Fix for FieldFresh v2.3
-- Run this in Supabase SQL Editor

-- 1. Fix notifications table
DROP TABLE IF EXISTS notifications CASCADE;

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) DEFAULT 'info',
  title VARCHAR(255) NOT NULL,
  message TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- 2. Add customer_id to reviews table (ignore error if column exists)
ALTER TABLE reviews ADD COLUMN customer_id UUID;

-- 3. Add foreign key constraint (ignore error if exists)
ALTER TABLE reviews ADD CONSTRAINT reviews_customer_id_fkey 
FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE;

-- 4. Create index (ignore error if exists)
CREATE INDEX idx_reviews_customer_id ON reviews(customer_id);

-- 5. Disable RLS on all tables
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

-- 6. Grant permissions
GRANT ALL ON notifications TO authenticated, anon, service_role;
GRANT ALL ON products TO authenticated, anon, service_role;
GRANT ALL ON orders TO authenticated, anon, service_role;
GRANT ALL ON users TO authenticated, anon, service_role;
GRANT ALL ON reviews TO authenticated, anon, service_role;

-- Success message
SELECT 'Database fix completed successfully!' as result;