# 🚀 FieldFresh - Advanced Features Quick Reference

## 📱 Customer App Features

### 1. Market Feed (Tab 1)
- **Freshness Score**: 0-100 score on each product (top-left badge)
- **Distance**: Shows km away from farmer (top-right badge)
- **Farmer Info**: Name and rating (bottom overlay)
- **Timer**: Real-time countdown to expiry
- **Filters**: Category chips (All, Vegetables, Fruits, etc.)
- **Search**: Search products by name
- **Sorting**: Smart algorithm (Distance 40% + Freshness 30% + Following 20% + Category 10%)

### 2. Farmers (Tab 2)
- **Nearby List**: Farmers within 25km, sorted by distance
- **Follow**: Heart button to follow/unfollow
- **Profile**: Click to view farmer profile
- **Verification**: Green checkmark for verified farmers
- **Rating**: Star rating display

### 3. Orders (Tab 3)
- **Order History**: All past orders
- **Status Tracking**: Real-time order status
- **Reorder**: Quick reorder button

### 4. Group Buy (Tab 4)
- **Active Groups**: List of active group buys
- **Progress**: Visual progress bar
- **Discount**: Discount percentage badge
- **Join**: Join group with one click
- **Timer**: Expiry countdown

### 5. Alerts (Tab 5)
- **Harvest Alerts**: New product notifications
- **Order Updates**: Order status changes
- **Group Buy**: Group buy updates

### 6. Profile (Tab 6)
- **Personal Info**: Name, phone, address
- **Order History**: Past orders
- **Followed Farmers**: List of followed farmers
- **Settings**: App settings

---

## 👨‍🌾 Farmer App Features

### 1. Dashboard (Tab 1)
- **Stats**: Active listings, orders, revenue
- **Quick Actions**: Post harvest, go live, analytics
- **Live Orders**: Real-time order stream
- **Go Live**: Start live streaming

### 2. Post (Tab 2)
- **Add Product**: Post new harvest
- **Photos**: Upload product images
- **Pricing**: Set price per unit
- **Quantity**: Set available quantity
- **Validity**: Set freshness duration

### 3. Orders (Tab 3)
- **Incoming Orders**: New orders
- **Order Management**: Accept/reject orders
- **Status Updates**: Update order status
- **History**: Past orders

### 4. Wallet (Tab 4)
- **Balance**: Current wallet balance
- **Transactions**: Transaction history
- **Withdraw**: Request payout
- **Revenue**: Total earnings

### 5. Profile (Tab 5)
- **Farm Info**: Name, location, bio
- **Verification**: Verification status
- **Rating**: Customer ratings
- **Settings**: Account settings

---

## 👨‍💼 Admin App Features

### 1. Dashboard (Tab 1)
- **Platform Stats**: Users, orders, revenue
- **Charts**: Visual analytics
- **Recent Activity**: Latest actions
- **Quick Actions**: Common admin tasks

### 2. Farmers (Tab 2)
- **Farmer List**: All registered farmers
- **Verification**: Approve/reject farmers
- **Details**: View farmer profiles
- **Products**: View farmer products

### 3. Customers (Tab 3)
- **Customer List**: All registered customers
- **Details**: View customer profiles
- **Orders**: View customer orders
- **Activity**: Customer activity log

### 4. Orders (Tab 4)
- **All Orders**: Platform-wide orders
- **Filters**: Filter by status
- **Details**: View order details
- **Disputes**: Handle disputes

### 5. Products (Tab 5)
- **All Products**: Platform-wide products
- **Moderation**: Approve/reject products
- **Categories**: Manage categories
- **Reports**: Product reports

---

## 🎯 Key Features Explained

### AI Freshness Score
**Formula**: Time (60%) + Rating (25%) + Distance (15%) = 100 points

**Score Breakdown**:
- **Time Score (60 points)**:
  - 0-2 hours: 60 points
  - 2-6 hours: 55 points
  - 6-12 hours: 50 points
  - 12-24 hours: 40 points
  - 24-48 hours: 30 points
  - 48+ hours: 20 points

- **Rating Score (25 points)**:
  - Farmer rating × 5
  - Example: 4.5 rating = 22.5 points

- **Distance Score (15 points)**:
  - 0-5 km: 15 points
  - 5-10 km: 12 points
  - 10-15 km: 10 points
  - 15-20 km: 7 points
  - 20-25 km: 5 points
  - 25+ km: 3 points

**Labels**:
- 90-100: Ultra Fresh 🌟
- 75-89: Very Fresh ✨
- 60-74: Fresh ✅
- 45-59: Good 👍
- 30-44: Aging ⚠️
- Below 30: Hidden ❌

---

### Privacy Protection System

**Before Payment (₹20)**:
- ✅ Farmer name
- ✅ Profile picture
- ✅ Rating
- ✅ District
- ✅ City
- ✅ Verification status
- ❌ Phone number
- ❌ GPS coordinates
- ❌ Full address

**After Payment (₹20)**:
- ✅ Everything above PLUS:
- ✅ Phone number (with copy button)
- ✅ GPS coordinates (with copy button)
- ✅ Full address (village, city, district, state)
- ✅ Navigation to farm

---

### Feed Algorithm

**Ranking Formula**:
```
Feed Score = Distance(40%) + Freshness(30%) + Following(20%) + Category(10%)
```

**Example Calculation**:
- Product A: 10km away, 85 freshness, followed farmer, preferred category
  - Distance: (25-10)/25 × 40 = 24 points
  - Freshness: 85/100 × 30 = 25.5 points
  - Following: 20 points
  - Category: 10 points
  - **Total: 79.5 points**

- Product B: 5km away, 70 freshness, not followed, different category
  - Distance: (25-5)/25 × 40 = 32 points
  - Freshness: 70/100 × 30 = 21 points
  - Following: 0 points
  - Category: 0 points
  - **Total: 53 points**

Product A ranks higher despite being farther because of following and category match.

---

### Group Buy System

**How It Works**:
1. Farmer/Customer creates group buy
2. Sets target quantity (e.g., 10 kg)
3. Sets discount (e.g., 15%)
4. Sets expiry time (e.g., 24 hours)
5. Customers join with quantity
6. Progress bar fills up
7. When target reached, group finalizes
8. All members get discount

**Benefits**:
- Customers: Save up to 20%
- Farmers: Bulk orders, guaranteed sales
- Platform: Higher GMV

---

## 🔑 Test Credentials

### Customer:
- Phone: `9876543210`
- OTP: Any 6 digits (demo mode)

### Farmer:
- Phone: `9876543211`
- OTP: Any 6 digits (demo mode)

### Admin:
- Tap logo 5 times on role select screen
- Code: `admin123`
- Phone: `9999999999`
- OTP: Any 6 digits (demo mode)

---

## 🎨 Color Codes

### Freshness Colors:
- Ultra Fresh: `#27AE60` (Green)
- Very Fresh: `#2ECC71` (Light Green)
- Fresh: `#52BE80` (Mint)
- Good: `#F39C12` (Orange)
- Aging: `#E67E22` (Dark Orange)
- Too Old: `#E74C3C` (Red)

### Timer Colors:
- > 6 hours: Green
- 2-6 hours: Orange
- < 2 hours: Red
- Expired: Red

### Status Colors:
- Pending: Orange
- Confirmed: Blue
- Packed: Purple
- Dispatched: Teal
- Delivered: Green
- Cancelled: Red

---

## 📊 Database Tables

### Core Tables:
1. **users** - All users (farmers, customers, admin)
2. **products** - All products posted by farmers
3. **orders** - All orders placed by customers
4. **reviews** - Customer reviews for farmers

### Advanced Tables:
5. **farmer_followers** - Customer-farmer following relationships
6. **advance_payments** - ₹20 advance payments for farmer details
7. **group_buys** - Group buy campaigns
8. **group_buy_members** - Members in each group buy
9. **notifications** - Push notifications
10. **wallet_transactions** - Farmer wallet transactions
11. **farmer_wallets** - Farmer wallet balances

---

## 🚀 Quick Commands

### Run App:
```bash
flutter run -d chrome
```

### Hot Reload:
```
Press 'r' in terminal
```

### Hot Restart:
```
Press 'R' in terminal
```

### Build APK:
```bash
flutter build apk --release
```

### Build Web:
```bash
flutter build web --release
```

---

## 📁 Important Files

### Services:
- `lib/services/supabase_service.dart` - All backend logic

### Customer Screens:
- `lib/features/customer/feed/customer_feed_screen.dart` - Market feed
- `lib/features/customer/farmers/nearby_farmers_screen.dart` - Farmers list
- `lib/features/customer/farmers/farmer_profile_screen.dart` - Farmer profile
- `lib/features/customer/group_buy/group_buy_screen.dart` - Group buy

### Farmer Screens:
- `lib/features/farmer/farmer_home.dart` - Farmer dashboard

### Admin Screens:
- `lib/features/admin/admin_home.dart` - Admin dashboard

### Database:
- `supabase/schema.sql` - Complete database schema

---

## 🎯 Success Indicators

### Feature Working If:
- ✅ Freshness scores appear on products
- ✅ Distance badges show on products
- ✅ Farmers list loads with distance
- ✅ Follow buttons toggle correctly
- ✅ Farmer profile shows locked/unlocked states
- ✅ Group buy progress bars update
- ✅ Category filters work
- ✅ Search filters products
- ✅ Timers count down in real-time
- ✅ Navigation works smoothly

---

## 📞 Quick Help

### Issue: Products not showing
**Fix**: Check Supabase connection and sample data

### Issue: Distance showing 0 km
**Fix**: Add GPS coordinates to farmer profiles

### Issue: Freshness score not showing
**Fix**: Verify product has created_at timestamp

### Issue: Follow button not working
**Fix**: Check if customer is logged in

### Issue: Group buy not loading
**Fix**: Verify group_buys table exists

---

## 🎉 You're Ready!

All advanced features are implemented and ready to test. Run the app and explore!

```bash
flutter run -d chrome
```

**Happy Testing! 🚀**
