# Progressive Disclosure & Advance Payment System

## Overview
This system implements controlled information disclosure based on payment and order status. Farmer details are progressively revealed as the customer commits to the purchase.

## Order Flow with Privacy Protection

### Stage 1: Product Browsing (No Payment)
**Customer sees:**
- Product name, price, quantity
- Freshness score
- Distance from farm
- Farmer first name only
- District only

**Hidden:**
- Full farmer name
- Phone number
- Village name
- City name
- Exact location
- Navigation map

**Example:**
```
Product: Fresh Tomatoes
Price: ₹40/kg
Farmer: Ramu
District: Karur
Distance: 3 km
```

### Stage 2: Advance Payment (10% booking)
**Customer pays:** 10% of order value as advance

**Newly visible:**
- Full farmer name
- Phone number (masked: +91 98XXXXXX45)
- District

**Still hidden:**
- Village name
- City name
- Exact location
- Navigation map

**Example:**
```
Farmer: Ramu Kumar
Phone: +91 98XXXXXX45
District: Karur
Status: Advance paid - Waiting for farmer confirmation
```

### Stage 3: Farmer Accepts Order
**Farmer action:** Accept/Reject order

**If accepted:**
- Order status: confirmed
- Customer can chat with farmer
- Estimated preparation time shown

**Notification to customer:**
```
✅ Order Confirmed!
Ramu Kumar accepted your order
Estimated ready time: 2 hours
```

### Stage 4: Farmer Packs Product
**Farmer action:** Mark as "packed"

**Newly visible (FULL DETAILS UNLOCKED):**
- Full farmer name
- Complete phone number
- Village name
- City name
- Exact farm location
- Navigation map
- Pickup instructions

**Example:**
```
Farmer: Ramu Kumar
Phone: +91 9876543211
Address: Kattur Village, Karur City, Karur District
Location: [View on Map]
[Navigate to Farm]
```

### Stage 5: Pickup/Delivery
**Customer action:** Pickup or receive delivery

**Order status:** in_transit → delivered

**Notification:**
```
📦 Order Ready for Pickup
Navigate to farm location
Contact: +91 9876543211
```

### Stage 6: Final Payment
**Customer pays:** Remaining 90%

**System processes:**
- Platform fee (5%)
- Farmer receives (95% of total)
- Order marked complete

**Notification to farmer:**
```
💰 Payment Received
Amount: ₹180 (after 5% platform fee)
Order completed successfully
```

## Database Schema Updates

### Add advance_payment field to orders:
```sql
ALTER TABLE orders ADD COLUMN advance_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE orders ADD COLUMN advance_paid BOOLEAN DEFAULT false;
ALTER TABLE orders ADD COLUMN advance_paid_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN packed_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN details_unlocked BOOLEAN DEFAULT false;
```

### Add notification tracking:
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  type VARCHAR(50), -- product_posted, advance_paid, order_confirmed, etc.
  title TEXT,
  message TEXT,
  data JSONB,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Notification Events

### 1. Farmer Posts Product
**Trigger:** New product created
**Recipients:** All customers within 25km
**Notification:**
```
🌾 Fresh Harvest Alert!
Fresh Tomatoes - ₹40/kg
Harvested today - 3 km away
```

### 2. Customer Pays Advance
**Trigger:** Advance payment successful
**Recipient:** Farmer
**Notification:**
```
💰 New Order Request
Customer: Kathir
Product: Tomatoes (2 kg)
Advance paid: ₹20
[Accept] [Reject]
```

### 3. Farmer Accepts Order
**Trigger:** Farmer clicks accept
**Recipient:** Customer
**Notification:**
```
✅ Order Confirmed
Ramu Kumar accepted your order
Preparing your fresh tomatoes
```

### 4. Farmer Packs Product
**Trigger:** Farmer marks as packed
**Recipient:** Customer
**Notification:**
```
📦 Order Ready!
Your order is packed and ready
Full farmer details now available
[View Location] [Call Farmer]
```

### 5. Customer Picks Up
**Trigger:** Order marked as delivered
**Recipient:** Farmer
**Notification:**
```
✅ Order Picked Up
Customer collected the order
Awaiting final payment
```

### 6. Final Payment Complete
**Trigger:** Final payment processed
**Recipients:** Both farmer and customer
**Notification to Farmer:**
```
💰 Payment Received
Amount: ₹180
Order #12345 completed
```

**Notification to Customer:**
```
✅ Order Complete
Thank you for your purchase!
Rate your experience
```

## Admin Panel Features

### Admin sees ALL details at every stage:
1. **All Orders Dashboard**
   - Order ID, status, amounts
   - Customer and farmer details
   - Payment status
   - Timeline of events

2. **User Management**
   - All farmer profiles
   - All customer accounts
   - Verification status
   - Activity logs

3. **Payment Tracking**
   - Advance payments
   - Final payments
   - Platform fees collected
   - Pending settlements

4. **Dispute Resolution**
   - Order issues
   - Payment disputes
   - Refund requests
   - Communication logs

5. **Analytics**
   - Daily orders
   - Revenue trends
   - Active users
   - Product categories

## Privacy Rules Implementation

### Product Detail Screen:
```dart
// Show limited info before advance payment
if (!order.advancePaid) {
  farmerName = farmer.name.split(' ')[0]; // First name only
  farmerPhone = 'Hidden until advance payment';
  farmerLocation = farmer.district; // District only
  showMap = false;
}

// Show partial info after advance payment
else if (order.advancePaid && !order.detailsUnlocked) {
  farmerName = farmer.name; // Full name
  farmerPhone = maskPhone(farmer.phone); // +91 98XXXXXX45
  farmerLocation = farmer.district;
  showMap = false;
}

// Show full info after order packed
else if (order.detailsUnlocked) {
  farmerName = farmer.name;
  farmerPhone = farmer.phone; // Full number
  farmerLocation = '${farmer.village}, ${farmer.city}, ${farmer.district}';
  showMap = true;
  showNavigation = true;
}
```

## Payment Flow

### Advance Payment (10%):
```dart
final orderTotal = quantity * pricePerUnit;
final advanceAmount = orderTotal * 0.10; // 10% advance
final remainingAmount = orderTotal * 0.90; // 90% remaining

// Process advance payment
await PaymentService.processAdvancePayment(
  orderId: orderId,
  amount: advanceAmount,
);

// Unlock partial details
await updateOrder(orderId, {
  'advance_paid': true,
  'advance_amount': advanceAmount,
  'advance_paid_at': DateTime.now(),
});
```

### Final Payment (90%):
```dart
// After customer confirms delivery
final remainingAmount = order.totalAmount - order.advanceAmount;

await PaymentService.processFinalPayment(
  orderId: orderId,
  amount: remainingAmount,
);

// Calculate platform fee and farmer payout
final platformFee = order.totalAmount * 0.05; // 5%
final farmerReceives = order.totalAmount * 0.95; // 95%
```

## Security Benefits

1. **Farmer Privacy Protected**
   - Location hidden until commitment
   - Phone number masked initially
   - Reduces spam/harassment

2. **Reduced Fake Orders**
   - Advance payment ensures commitment
   - Filters out non-serious buyers
   - Protects farmer time

3. **Platform Control**
   - All transactions through platform
   - Commission guaranteed
   - Dispute resolution possible

4. **Trust Building**
   - Progressive disclosure builds trust
   - Payment milestones reduce risk
   - Clear communication at each stage

## Implementation Priority

### Phase 1 (Critical):
1. ✅ Advance payment system
2. ✅ Privacy rules for farmer details
3. ✅ Order status pipeline
4. ✅ Basic notifications

### Phase 2 (Important):
1. ✅ Full notification system
2. ✅ Admin monitoring panel
3. ✅ Real-time updates
4. ✅ Payment tracking

### Phase 3 (Enhancement):
1. ⏳ In-app chat
2. ⏳ Dispute resolution
3. ⏳ Rating system
4. ⏳ Analytics dashboard

## Next Steps

1. Update database schema
2. Implement privacy rules in product detail screen
3. Add advance payment flow
4. Create notification service
5. Update admin panel
6. Test complete flow

This system transforms your app into a professional marketplace with proper privacy controls and payment security!
