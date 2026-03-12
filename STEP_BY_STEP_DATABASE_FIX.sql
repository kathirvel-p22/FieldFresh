-- Step-by-Step Database Fix for FieldFresh v2.3
-- Run each section separately if needed

-- STEP 1: Fix notifications table
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

SELECT 'Step 1 completed: Notifications table fixed' as result;

-- STEP 2: Fix reviews table (run this separately if Step 1 worked)
-- Add customer_id column to reviews table
ALTER TABLE reviews ADD COLUMN customer_id UUID;

-- Add foreign key constraint
ALTER TABLE reviews ADD CONSTRAINT reviews_customer_id_fkey 
FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE;

-- Create index
CREATE INDEX idx_reviews_customer_id ON reviews(customer_id);

SELECT 'Step 2 completed: Reviews table updated with customer_id' as result;
-- STEP 3: Disable RLS and grant permissions (run this last)
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE reviews DISABLE ROW LEVEL SECURITY;

GRANT ALL ON notifications TO authenticated, anon, service_role;
GRANT ALL ON products TO authenticated, anon, service_role;
GRANT ALL ON orders TO authenticated, anon, service_role;
GRANT ALL ON users TO authenticated, anon, service_role;
GRANT ALL ON reviews TO authenticated, anon, service_role;

SELECT 'Step 3 completed: RLS disabled and permissions granted' as result;