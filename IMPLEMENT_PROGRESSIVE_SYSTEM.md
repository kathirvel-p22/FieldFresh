# Implementation Guide: Progressive Disclosure System

## Overview
This guide provides step-by-step instructions to implement the advance payment and progressive farmer detail disclosure system.

## Phase 1: Database Updates (Run in Supabase SQL Editor)

```sql
-- Add advance payment fields to orders table
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

-- Create index for faster queries
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
  IF NEW.advance_paid = true AND OLD.advance_paid = false THEN
    PERFORM send_notification(
      NEW.farmer_id,
      'advance_paid',
      '💰 New Order Request',
      'Customer paid advance for ' || NEW.product_name,
      jsonb_build_object('order_id', NEW.id, 'amount', NEW.advance_amount)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_farmer_advance_paid
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_farmer_advance_paid();

-- Trigger: Notify customer when farmer accepts
CREATE OR REPLACE FUNCTION notify_customer_order_accepted()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
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

CREATE TRIGGER trigger_notify_customer_order_accepted
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_customer_order_accepted();

-- Trigger: Notify customer when order packed (unlock details)
CREATE OR REPLACE FUNCTION notify_customer_order_packed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'packed' AND OLD.status != 'packed' THEN
    -- Unlock farmer details
    UPDATE orders SET details_unlocked = true, packed_at = NOW()
    WHERE id = NEW.id;
    
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

CREATE TRIGGER trigger_notify_customer_order_packed
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_customer_order_packed();

-- Trigger: Notify both when order delivered
CREATE OR REPLACE FUNCTION notify_order_delivered()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
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

CREATE TRIGGER trigger_notify_order_delivered
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION notify_order_delivered();

-- Trigger: Notify customers when farmer posts product
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
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_customers_new_product
AFTER INSERT ON products
FOR EACH ROW
EXECUTE FUNCTION notify_customers_new_product();
```

## Phase 2: Update Product Detail Screen

Key changes needed in `lib/features/customer/feed/product_detail_screen.dart`:

1. Show limited farmer info initially
2. Add "Pay Advance" button (10% of order value)
3. Show partial info after advance payment
4. Show full info after order packed

## Phase 3: Update Checkout Flow

Modify `lib/features/customer/order/checkout_screen.dart`:

1. Calculate advance amount (10%)
2. Process advance payment first
3. Create order with advance_paid = true
4. Notify farmer

## Phase 4: Update Farmer Orders Screen

Modify `lib/features/farmer/orders/farmer_orders_screen.dart`:

1. Show "Accept/Reject" buttons for pending orders with advance paid
2. Add "Mark as Packed" button for confirmed orders
3. Show order timeline

## Phase 5: Create Notification Service

Create `lib/services/notification_service.dart`:

```dart
class NotificationService {
  static Stream<List<Map<String, dynamic>>> listenToNotifications(String userId) {
    return Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
  
  static Future<void> markAsRead(String notificationId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }
  
  static Future<int> getUnreadCount(String userId) async {
    final response = await Supabase.instance.client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);
    return response.length;
  }
}
```

## Phase 6: Create Notifications Screen

Create `lib/features/notifications/notifications_screen.dart`:

- List all notifications
- Mark as read
- Navigate to relevant screen on tap
- Show unread badge

## Phase 7: Update Admin Panel

Add to admin dashboard:

1. All orders with full details
2. Payment tracking (advance + final)
3. Notification logs
4. User activity timeline

## Testing Checklist

### Test 1: Product Browsing
- [ ] Customer sees limited farmer info (first name, district only)
- [ ] Phone number hidden
- [ ] Location hidden
- [ ] Map not visible

### Test 2: Advance Payment
- [ ] Customer pays 10% advance
- [ ] Farmer receives notification
- [ ] Customer sees full name and masked phone
- [ ] Location still hidden

### Test 3: Farmer Accepts
- [ ] Farmer clicks accept
- [ ] Customer receives notification
- [ ] Order status changes to confirmed

### Test 4: Farmer Packs
- [ ] Farmer marks as packed
- [ ] Customer receives notification
- [ ] Full farmer details unlocked
- [ ] Map and navigation visible
- [ ] Complete phone number shown

### Test 5: Delivery
- [ ] Customer confirms delivery
- [ ] Both receive notifications
- [ ] Final payment processed
- [ ] Platform fee calculated

### Test 6: Notifications
- [ ] All notifications appear in real-time
- [ ] Unread count updates
- [ ] Notifications marked as read
- [ ] Navigation works

### Test 7: Admin Panel
- [ ] Admin sees all order details
- [ ] Payment tracking visible
- [ ] User details accessible
- [ ] Notification logs available

## Privacy Rules Summary

| Stage | Farmer Name | Phone | Location | Map |
|-------|-------------|-------|----------|-----|
| Browsing | First name only | Hidden | District only | ❌ |
| Advance Paid | Full name | Masked | District only | ❌ |
| Order Packed | Full name | Full number | Full address | ✅ |

## Payment Breakdown

```
Order Total: ₹200
├── Advance (10%): ₹20 (paid immediately)
└── Final (90%): ₹180 (paid on delivery)
    ├── Platform Fee (5%): ₹10
    └── Farmer Receives (95%): ₹190
```

## Implementation Timeline

- **Week 1**: Database updates + notification system
- **Week 2**: Privacy rules + advance payment
- **Week 3**: Farmer order management + packing
- **Week 4**: Notifications UI + admin panel
- **Week 5**: Testing + bug fixes

## Benefits

1. ✅ Farmer privacy protected
2. ✅ Reduced fake orders
3. ✅ Payment commitment ensured
4. ✅ Platform control maintained
5. ✅ Professional marketplace experience

This system transforms your app into a secure, privacy-focused marketplace!
