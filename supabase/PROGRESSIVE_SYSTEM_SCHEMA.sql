-- Progressive Disclosure System Database Schema
-- Run this in Supabase SQL Editor

-- Add advance payment and privacy fields to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS advance_amount DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS advance_paid BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS advance_paid_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS packed_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS details_unlocked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS farmer_accepted_at TIMESTAMP;

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_advance_paid ON orders(advance_paid);
CREATE INDEX IF NOT EXISTS idx_orders_details_unlocked ON orders(details_unlocked);

-- Function to send notification
CREATE OR REPLACE FUNCTION send_notification(
  p_user_id UUID,
  p_type VARCHAR,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data)
  RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Notify farmer when advance paid
CREATE OR REPLACE FUNCTION notify_farmer_advance_paid()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.advance_paid = true AND (OLD.advance_paid IS NULL OR OLD.advance_paid = false) THEN
    PERFORM send_notification(
      NEW.farmer_id,
      'advance_paid',
      '💰 New Order Request',
      'Customer paid advance for ' || NEW.product_name || ' (₹' || NEW.advance_amount || ')',
      jsonb_build_object('order_id', NEW.id, 'amount', NEW.advance_amount)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_farmer_advance_paid ON orders;
CREATE TRIGGER trigger_notify_farmer_advance_paid
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_farmer_advance_paid();

-- Trigger: Notify customer when farmer accepts
CREATE OR REPLACE FUNCTION notify_customer_order_accepted()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status = 'pending') THEN
    PERFORM send_notification(
      NEW.customer_id,
      'order_confirmed',
      '✅ Order Confirmed',
      'Farmer accepted your order for ' || NEW.product_name,
      jsonb_build_object('order_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_customer_order_accepted ON orders;
CREATE TRIGGER trigger_notify_customer_order_accepted
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_customer_order_accepted();

-- Trigger: Notify customer when order packed (unlock details)
CREATE OR REPLACE FUNCTION notify_customer_order_packed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'packed' AND (OLD.status IS NULL OR OLD.status != 'packed') THEN
    -- Unlock farmer details
    NEW.details_unlocked := true;
    NEW.packed_at := NOW();
    
    PERFORM send_notification(
      NEW.customer_id,
      'order_packed',
      '📦 Order Ready!',
      'Your order is packed. Full farmer details now available.',
      jsonb_build_object('order_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_customer_order_packed ON orders;
CREATE TRIGGER trigger_notify_customer_order_packed
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_customer_order_packed();

-- Trigger: Notify both when order delivered
CREATE OR REPLACE FUNCTION notify_order_delivered()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
    -- Notify customer
    PERFORM send_notification(
      NEW.customer_id,
      'order_delivered',
      '✅ Order Complete',
      'Thank you for your purchase! Please rate your experience.',
      jsonb_build_object('order_id', NEW.id)
    );
    
    -- Notify farmer
    PERFORM send_notification(
      NEW.farmer_id,
      'order_delivered',
      '✅ Order Delivered',
      'Customer confirmed delivery. Payment will be processed.',
      jsonb_build_object('order_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_order_delivered ON orders;
CREATE TRIGGER trigger_notify_order_delivered
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_order_delivered();

-- Trigger: Notify customers when farmer posts product (within 25km)
CREATE OR REPLACE FUNCTION notify_customers_new_product()
RETURNS TRIGGER AS $$
DECLARE
  customer_record RECORD;
  farmer_location GEOGRAPHY;
  customer_location GEOGRAPHY;
  distance_km NUMERIC;
BEGIN
  -- Get farmer location
  SELECT ST_MakePoint(longitude, latitude)::geography INTO farmer_location
  FROM users WHERE id = NEW.farmer_id;
  
  -- Only proceed if farmer has location
  IF farmer_location IS NOT NULL THEN
    -- Notify customers within 25km
    FOR customer_record IN 
      SELECT id, ST_MakePoint(longitude, latitude)::geography as location
      FROM users 
      WHERE role = 'customer' AND latitude IS NOT NULL AND longitude IS NOT NULL
    LOOP
      distance_km := ST_Distance(farmer_location, customer_record.location) / 1000;
      
      IF distance_km <= 25 THEN
        PERFORM send_notification(
          customer_record.id,
          'new_product',
          '🌾 Fresh Harvest Alert!',
          NEW.name || ' - ₹' || NEW.price || '/' || NEW.unit || ' - ' || ROUND(distance_km, 1) || ' km away',
          jsonb_build_object('product_id', NEW.id, 'distance', distance_km)
        );
      END IF;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_customers_new_product ON products;
CREATE TRIGGER trigger_notify_customers_new_product
AFTER INSERT ON products
FOR EACH ROW
EXECUTE FUNCTION notify_customers_new_product();

-- Verify setup
SELECT 'Progressive disclosure system schema created successfully!' as status;
