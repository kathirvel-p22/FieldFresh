# 🧪 Testing Advanced Features Guide

## Quick Start

### 1. Run the Application
```bash
flutter run -d chrome
```

### 2. Login as Customer
- Phone: `9876543210` (any 10-digit number)
- Role: Customer
- OTP: Any 6 digits (demo mode)

---

## 🎯 Feature Testing Checklist

### ✅ 1. AI Freshness Score System

**What to Test**:
- Open the app and go to "Market" tab
- Look at product cards - each should have a freshness score badge (top-left)
- Scores should be 0-100 with color coding:
  - Green (90-100): Ultra Fresh
  - Light Green (75-89): Very Fresh
  - Yellow (60-74): Fresh
  - Orange (45-59): Good
  - Red (30-44): Aging

**Expected Behavior**:
- Products with score < 30 should NOT appear in feed
- Scores update based on harvest time, farmer rating, and distance
- Color changes based on score

**Screenshot Locations**:
- Top-left corner of each product card

---

### ✅ 2. Real-Time Location & Distance

**What to Test**:
- Open "Market" tab
- Look at product cards - each should have a distance badge (top-right)
- Distance should show in kilometers (e.g., "2.5 km")

**Expected Behavior**:
- Only products within 25km radius appear
- Products sorted by feed algorithm (not just distance)
- Distance calculated using Haversine formula

**Screenshot Locations**:
- Top-right corner of each product card

---

### ✅ 3. Nearby Farmers Discovery

**What to Test**:
1. Click on "Farmers" tab (second tab)
2. Should see list of farmers within 25km
3. Each farmer card shows:
   - Profile picture
   - Name with verification badge (if verified)
   - Location (district, city)
   - Distance in km
   - Star rating
   - Follow/unfollow heart button

**Expected Behavior**:
- Farmers sorted by distance (closest first)
- Verified farmers have green checkmark badge
- Heart button toggles between filled (following) and outline (not following)
- Pull down to refresh

**Actions to Try**:
- Click heart icon to follow a farmer
- Heart should turn red
- Click again to unfollow
- Pull down to refresh list

---

### ✅ 4. Farmer Profile with Privacy Protection

**What to Test**:
1. Go to "Farmers" tab
2. Click on any farmer card
3. Should see farmer profile with:
   - **Before Payment** (Locked):
     - Name
     - Rating
     - District and City only
     - Locked card with "Pay ₹20 & Unlock Details" button
   - **After Payment** (Unlocked):
     - Phone number (with copy button)
     - Full address (village, city, district, state)
     - GPS coordinates (with copy button)

**Expected Behavior**:
- Initially shows limited info
- Click "Pay ₹20 & Unlock Details" button
- Payment processes (demo mode - instant)
- Full details unlock automatically
- Copy buttons work for phone and GPS

**Actions to Try**:
- View locked profile
- Click unlock button
- Verify full details appear
- Click copy buttons to copy phone/GPS

---

### ✅ 5. Farmer Following System

**What to Test**:
1. Go to "Farmers" tab
2. Click heart icon on any farmer card
3. Heart should fill with red color
4. Go to farmer profile
5. Heart icon in app bar should also be filled

**Expected Behavior**:
- Follow status syncs across all screens
- Followed farmers get 20% boost in feed ranking
- Can follow/unfollow from:
  - Farmers list
  - Farmer profile
  - Product detail page (future)

**Actions to Try**:
- Follow 2-3 farmers
- Check if their products appear higher in Market feed
- Unfollow and check feed again

---

### ✅ 6. Group Buy Feature

**What to Test**:
1. Go to "Group Buy" tab (4th tab)
2. Should see banner explaining group buy
3. Below should show active group buys with:
   - Product name and emoji
   - Farmer name
   - Discount percentage badge
   - Price per unit
   - Progress bar showing members joined
   - "X of Y members joined" text
   - Time left timer
   - Join button

**Expected Behavior**:
- Progress bar fills as more members join
- When target reached, button changes to "Finalize Group Order"
- Timer counts down to expiry
- Join button adds you to the group

**Actions to Try**:
- Click "Join This Group" button
- Should see success message
- Progress bar should update
- Pull down to refresh and see updated data

**Create Group Buy** (Future):
- Click "Start Group" button in app bar
- Dialog appears (feature coming soon)

---

### ✅ 7. Enhanced Product Feed

**What to Test**:
1. Go to "Market" tab
2. Each product card should show:
   - Product image or category emoji
   - Freshness score badge (top-left)
   - Distance badge (top-right)
   - Farmer name and rating (bottom overlay)
   - Product name
   - Price per unit
   - Countdown timer with color coding
   - "Order Now" button

**Expected Behavior**:
- Timer counts down in real-time
- Timer color changes:
  - Green: > 6 hours left
  - Orange: 2-6 hours left
  - Red: < 2 hours left
- Products auto-hide when expired
- Pull down to refresh

**Actions to Try**:
- Scroll through products
- Watch timers count down
- Filter by category (chips at top)
- Search for products
- Pull down to refresh

---

### ✅ 8. Category Filtering

**What to Test**:
1. Go to "Market" tab
2. See category chips below search bar:
   - All 🌱
   - Vegetables 🥬
   - Fruits 🍎
   - Dairy 🥛
   - Grains 🌾
   - Eggs 🥚
   - Honey 🍯

**Expected Behavior**:
- Click category chip to filter
- Selected chip turns green
- Products filter to show only that category
- Click "All" to show all products

**Actions to Try**:
- Click each category
- Verify products filter correctly
- Click "All" to reset

---

### ✅ 9. Search Functionality

**What to Test**:
1. Go to "Market" tab
2. Click search bar at top
3. Type product name (e.g., "tomato")

**Expected Behavior**:
- Products filter as you type
- Shows only matching products
- Case-insensitive search
- Clear search to show all products

**Actions to Try**:
- Search for "tomato"
- Search for "mango"
- Clear search
- Search for partial names

---

### ✅ 10. Navigation & UI

**What to Test**:
1. Bottom navigation bar should have 6 tabs:
   - Market (storefront icon)
   - Farmers (agriculture icon)
   - Orders (receipt icon)
   - Group Buy (group icon)
   - Alerts (notification icon)
   - Profile (person icon)

**Expected Behavior**:
- Tap each tab to navigate
- Selected tab highlighted
- Smooth transitions
- No lag or freezing

**Actions to Try**:
- Navigate through all tabs
- Go back and forth
- Check if state persists (e.g., scroll position)

---

## 🐛 Common Issues & Solutions

### Issue: Products not showing
**Solution**: 
- Check if sample data is loaded in Supabase
- Run SQL from `supabase/schema.sql`
- Verify products have valid `valid_until` dates

### Issue: Distance showing as 0 km
**Solution**:
- Check if farmers have GPS coordinates (latitude, longitude)
- Update farmer profiles with location data

### Issue: Freshness score not showing
**Solution**:
- Verify products have `created_at` timestamp
- Check if farmer has rating (default 0.0)
- Ensure distance is calculated

### Issue: Group buy not loading
**Solution**:
- Check if `group_buys` table exists
- Verify sample group buy data is inserted
- Check if products are linked correctly

### Issue: Follow button not working
**Solution**:
- Verify `farmer_followers` table exists
- Check if customer is logged in
- Verify customer ID is set

---

## 📊 Expected Data Flow

### 1. Customer Opens App
```
1. Login with phone number
2. Set demo user ID in SupabaseService
3. Load customer location (demo: Coimbatore)
4. Fetch nearby products with scores
5. Calculate freshness scores
6. Calculate distances
7. Sort by feed algorithm
8. Display in Market feed
```

### 2. Customer Views Farmer
```
1. Click on farmer card
2. Check if advance payment exists
3. If NO: Show limited details + locked card
4. If YES: Show full details (phone, GPS, address)
5. Load follow status
6. Display profile
```

### 3. Customer Joins Group Buy
```
1. Click "Join This Group" button
2. Verify customer is logged in
3. Insert into group_buy_members table
4. Update current_quantity in group_buys table
5. Show success message
6. Refresh group buy list
```

---

## 🎯 Success Criteria

### All features working if:
- ✅ Freshness scores appear on all products
- ✅ Distance badges show on all products
- ✅ Farmers list loads with distance sorting
- ✅ Farmer profile shows locked/unlocked states
- ✅ Follow buttons work and sync across screens
- ✅ Group buy progress bars update
- ✅ Category filters work
- ✅ Search filters products
- ✅ Timers count down in real-time
- ✅ Navigation works smoothly

---

## 📸 Screenshot Checklist

Take screenshots of:
1. Market feed with freshness scores and distance badges
2. Farmers list with distance and ratings
3. Farmer profile (locked state)
4. Farmer profile (unlocked state)
5. Group buy list with progress bars
6. Category filters
7. Search results
8. Product detail page

---

## 🚀 Next Steps After Testing

If all features work:
1. ✅ Test on Android device
2. ✅ Test on iOS device
3. ✅ Add more sample data
4. ✅ Implement push notifications
5. ✅ Add live streaming
6. ✅ Integrate payment gateway
7. ✅ Add maps view
8. ✅ Deploy to production

---

## 📞 Support

If you encounter any issues:
1. Check console logs for errors
2. Verify Supabase connection
3. Check database schema
4. Review `ADVANCED_FEATURES_COMPLETE.md`
5. Check `lib/services/supabase_service.dart` for implementation

---

**Happy Testing! 🎉**

All advanced features are now live and ready to test!
