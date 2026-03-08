# FieldFresh - Simplified System

## ✅ System Updated: Farmer-to-Customer Direct Platform

The system has been simplified to focus on direct farmer-to-customer transactions, removing the delivery partner role.

## System Roles

### 1. 👨‍🌾 Farmer
**Purpose:** Sell produce directly to customers

**Features:**
- Post harvest/products with photos, prices, quantities
- Receive orders from customers
- Update order status (pending → confirmed → packed → dispatched → delivered)
- Track earnings and wallet balance
- View customer details
- Manage product listings
- Go live to showcase products
- View analytics and sales reports

**Dashboard Sections:**
- Active Listings
- Total Orders
- Pending Orders
- Revenue
- Live Orders Stream
- Quick Actions (Post Harvest, Go Live, Analytics)

### 2. 🛒 Customer
**Purpose:** Buy fresh produce directly from farmers

**Features:**
- Browse products from nearby farmers
- Filter by category (vegetables, fruits, grains, dairy, etc.)
- View product details with photos
- Place orders (delivery or pickup)
- Track order status in real-time
- Make payments (online/COD)
- Rate and review farmers
- View order history
- Save favorite farmers
- Get notifications for new products

**Dashboard Sections:**
- Nearby Products Feed
- Categories
- Active Orders
- Order History
- Saved Farmers
- Profile & Settings

### 3. 🔐 Admin
**Purpose:** Manage and monitor the entire platform

**Features:**
- View all farmers with details
- View all customers with details
- Monitor all orders across platform
- Filter orders by status
- Update order status
- View all products
- Track platform revenue (5% commission)
- View analytics and charts
- Manage user verification
- Resolve disputes
- Payment tracking
- Generate reports

**Dashboard Sections:**
- Total Farmers Count
- Total Customers Count
- Total Orders Count
- Platform Revenue
- Monthly GMV Chart
- Quick Actions:
  - View Farmers
  - View Customers
  - All Orders
  - All Products
  - Analytics
  - Settings

## Order Flow

### Direct Farmer-to-Customer:
```
1. Customer browses products
2. Customer places order
3. Farmer receives notification
4. Farmer confirms order
5. Farmer packs the order
6. Farmer dispatches (self-delivery or courier)
7. Customer receives order
8. Customer confirms delivery
9. Payment released to farmer
10. Customer can rate/review
```

### Order Statuses:
- **Pending** - Order placed, waiting for farmer confirmation
- **Confirmed** - Farmer accepted the order
- **Packed** - Order is packed and ready
- **Dispatched** - Order is on the way
- **Delivered** - Order delivered successfully
- **Cancelled** - Order cancelled

## Delivery Options

### 1. Self-Delivery by Farmer
- Farmer delivers directly to customer
- Best for local/nearby customers
- Lower cost, more personal

### 2. Courier/Third-Party
- Farmer uses external courier service
- For distant customers
- Tracking via courier service

### 3. Customer Pickup
- Customer picks up from farm
- Zero delivery cost
- Fresh from farm

## Payment System

### Payment Methods:
1. **Online Payment** (UPI, Cards, Wallets)
   - Instant confirmation
   - Secure transactions
   - Payment held until delivery

2. **Cash on Delivery (COD)**
   - Pay when you receive
   - Farmer collects cash
   - Updates payment status

### Payment Flow:
```
Customer → Platform (5% commission) → Farmer Wallet (95%)
```

### Farmer Wallet:
- Track all earnings
- View transaction history
- Request payouts
- Minimum payout: ₹500
- Payout within 2-3 business days

## Key Features

### For Farmers:
✅ Easy product posting with photos
✅ Real-time order notifications
✅ Direct customer communication
✅ Wallet and earnings tracking
✅ Live streaming to showcase products
✅ Analytics and insights
✅ Multiple delivery options

### For Customers:
✅ Fresh produce from local farmers
✅ Transparent pricing
✅ Real-time order tracking
✅ Multiple payment options
✅ Rate and review system
✅ Save favorite farmers
✅ Category-wise browsing

### For Admin:
✅ Complete platform oversight
✅ User management
✅ Order monitoring and management
✅ Revenue tracking
✅ Analytics dashboard
✅ Dispute resolution
✅ Payment verification

## Database Schema

### Users Table:
- id, phone, name, role (farmer/customer/admin)
- profile_image, address, latitude, longitude
- rating, is_verified, is_kyc_done
- fcm_token, created_at, updated_at

### Products Table:
- id, farmer_id, name, category
- description, price_per_unit, unit
- quantity_left, image_urls
- valid_until, status (active/sold_out)
- created_at, updated_at

### Orders Table:
- id, customer_id, farmer_id, product_id
- product_name, quantity, unit
- price_per_unit, total_amount
- delivery_type (delivery/pickup)
- delivery_address, latitude, longitude
- status, payment_status, payment_id
- confirmed_at, delivered_at
- created_at, updated_at

### Farmer Wallets Table:
- id, farmer_id, balance
- total_earned, total_withdrawn
- created_at, updated_at

### Wallet Transactions Table:
- id, farmer_id, order_id
- type (credit/debit), amount
- balance_after, description
- created_at

## Test Credentials

### Farmers:
- Phone: `9876543210` (Ramu Farmer)
- Phone: `9876543211` (Geetha Devi)
- Phone: `9876543212` (Muthu Kumar)

### Admin:
- Phone: `9999999999`
- Or tap logo 5x, code: `admin123`

### New User:
- Any other 10-digit number

## Files Updated

### Removed Delivery Role:
1. ✅ `lib/features/auth/role_select_screen.dart` - Removed delivery option
2. ✅ `lib/features/auth/login_screen.dart` - Removed delivery from roleData
3. ✅ `lib/features/auth/kyc_screen.dart` - Removed delivery from roleData

### System Now Has:
- 2 User Roles: Farmer & Customer
- 1 Admin Role: Platform Management
- Direct farmer-to-customer transactions
- Simplified order flow
- Multiple delivery options (self/courier/pickup)

## How to Test

1. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

2. **Test as Farmer:**
   - Select "Farmer" role
   - Login with: `9876543210`
   - Post products, manage orders

3. **Test as Customer:**
   - Select "Customer" role
   - Login with any new number
   - Browse products, place orders

4. **Test as Admin:**
   - Tap logo 5 times
   - Enter code: `admin123`
   - Login with: `9999999999`
   - Access all admin features

## Benefits of Simplified System

✅ **For Farmers:**
- Higher profit margins (no middleman)
- Direct customer relationships
- Flexible delivery options
- Better control over business

✅ **For Customers:**
- Lower prices (no middleman markup)
- Fresher produce (direct from farm)
- Know your farmer
- Support local agriculture

✅ **For Platform:**
- Simpler to manage
- Lower operational costs
- Faster transactions
- Better user experience

The system is now a pure farmer-to-customer marketplace! 🌾🛒
