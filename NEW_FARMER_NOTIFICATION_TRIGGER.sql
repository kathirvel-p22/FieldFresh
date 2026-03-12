-- Database trigger to automatically notify customers when a new farmer signs up
-- This ensures real-time updates across all customer panels

-- Function to notify customers about new farmers
CREATE OR REPLACE FUNCTION notify_customers_new_farmer()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger for new farmer registrations that are verified
  IF NEW.role = 'farmer' AND NEW.is_verified = true AND (OLD IS NULL OR OLD.is_verified = false) THEN
    
    -- Insert notifications for all customers
    INSERT INTO notifications (user_id, title, message, type, data, is_read, sent_at)
    SELECT 
      u.id,
      'New Farmer Joined! 👨‍🌾',
      NEW.name || ' from ' || COALESCE(NEW.city, 'your area') || ' is now selling fresh produce',
      'new_farmer',
      jsonb_build_object('farmer_id', NEW.id, 'farmer_name', NEW.name),
      false,
      NOW()
    FROM users u
    WHERE u.role = 'customer';
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new farmer notifications
DROP TRIGGER IF EXISTS trigger_notify_new_farmer ON users;
CREATE TRIGGER trigger_notify_new_farmer
  AFTER INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION notify_customers_new_farmer();

-- Function to notify customers when farmer updates profile
CREATE OR REPLACE FUNCTION notify_customers_farmer_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger for significant farmer profile updates
  IF NEW.role = 'farmer' AND NEW.is_verified = true AND OLD IS NOT NULL THEN
    
    -- Check if important fields changed
    IF OLD.name != NEW.name OR OLD.city != NEW.city OR OLD.profile_image != NEW.profile_image THEN
      
      -- Insert notifications for customers who follow this farmer
      INSERT INTO notifications (user_id, title, message, type, data, is_read, sent_at)
      SELECT 
        ff.customer_id,
        'Farmer Profile Updated 📝',
        NEW.name || ' updated their profile information',
        'farmer_update',
        jsonb_build_object('farmer_id', NEW.id, 'farmer_name', NEW.name),
        false,
        NOW()
      FROM farmer_followers ff
      WHERE ff.farmer_id = NEW.id;
      
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for farmer profile updates
DROP TRIGGER IF EXISTS trigger_notify_farmer_update ON users;
CREATE TRIGGER trigger_notify_farmer_update
  AFTER UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION notify_customers_farmer_update();

-- Test the triggers (optional)
-- You can test by updating a farmer's verification status:
-- UPDATE users SET is_verified = true WHERE role = 'farmer' AND name = 'Test Farmer';

-- Check if triggers were created successfully
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing
FROM information_schema.triggers 
WHERE trigger_name IN ('trigger_notify_new_farmer', 'trigger_notify_farmer_update');