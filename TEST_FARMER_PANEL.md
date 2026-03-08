# 🧪 Testing Farmer Panel - Complete Guide

## Quick Start

### 1. Run the Application
```bash
flutter run -d chrome
```

### 2. Login as Farmer
- Phone: `9876543211`
- OTP: Any 6 digits (demo mode)
- Complete KYC if needed

---

## 🎯 Feature Testing Checklist

### ✅ 1. Post Product (Tab 2)

**Steps**:
1. Click on "Post" tab (+ icon)
2. Add product images (click camera icon)
3. Select category (e.g., Vegetables)
4. Enter product name (e.g., "Fresh Tomatoes")
5. Enter price (e.g., 45)
6. Select unit (kg)
7. Enter quantity (e.g., 50)
8. Adjust validity slider (e.g., 12 hours)
9. Add description (optional)
10. Wait for GPS location detection
11. Click "POST" button

**Expected Result**:
- ✅ Product posted successfully
- ✅ Success message appears
- ✅ Harvest blast notification sent
- ✅ Form clears for next product
- ✅ No "farm_address" error

**Screenshot**: Product posted with green success message

---

### ✅ 2. Sales Analytics (Profile → Sales Analytics)

**Steps**:
1. Go to Profile tab (person icon)
2. Click "Sales Analytics"
3. View revenue card
4. Check stats grid
5. Scroll to category sales
6. Pull down to refresh

**Expected Result**:
- ✅ Revenue card shows total earnings
- ✅ Completed orders count displayed
- ✅ Success rate percentage shown
- ✅ Stats cards show:
  - Total orders
  - Pending orders
  - Active products
  - Average order value
- ✅ Category-wise sales with progress bars
- ✅ Pull-to-refresh works

**What to Check**:
- Revenue calculation is correct
- Order counts match dashboard
- Category breakdown makes sense
- Progress bars fill correctly

---

### ✅ 3. My Listings (Profile → My Listings)

**Steps**:
1. Go to Profile tab
2. Click "My Listings"
3. View all products
4. Click "Active" filter
5. Click "Expired" filter
6. Click "Sold Out" filter
7. Click "All" filter
8. Try delete button on a product
9. Confirm deletion
10. Pull down to refresh

**Expected Result**:
- ✅ All products displayed
- ✅ Filter chips work correctly
- ✅ Product cards show:
  - Product image
  - Name and price
  - Quantity left/total
  - Time remaining
  - Status badge (Active/Expired/Sold Out)
- ✅ Delete confirmation dialog appears
- ✅ Product deleted successfully
- ✅ Pull-to-refresh works

**Status Colors**:
- Active: Green badge
- Expired: Red badge
- Sold Out: Orange badge

---

### ✅ 4. Customer Reviews (Profile → Customer Reviews)

**Steps**:
1. Go to Profile tab
2. Click "Customer Reviews"
3. View rating summary
4. Check rating distribution
5. Scroll through reviews
6. Pull down to refresh

**Expected Result**:
- ✅ Average rating displayed (large number)
- ✅ Star rating visualization
- ✅ Total reviews count
- ✅ Rating distribution bars (5, 4, 3, 2, 1 stars)
- ✅ Review cards show:
  - Customer name and avatar
  - Time ago
  - Star rating
  - Freshness rating (if available)
  - Review comment
- ✅ Pull-to-refresh works

**If No Reviews**:
- Empty state message appears
- "No reviews yet" text
- "Complete orders to receive reviews" hint

---

### ✅ 5. Bank/UPI Settings (Profile → Bank / UPI Settings)

**Steps**:
1. Go to Profile tab
2. Click "Bank / UPI Settings"
3. Select "UPI" payment method
4. Enter UPI ID (e.g., farmer@paytm)
5. Click "SAVE" button
6. Go back and reopen
7. Verify UPI ID is saved
8. Select "Bank Account" method
9. Enter bank details:
   - Account holder name
   - Account number
   - IFSC code
   - Bank name
10. Click "SAVE" button
11. Go back and reopen
12. Verify bank details are saved

**Expected Result**:
- ✅ Payment method cards work
- ✅ UPI form validates:
  - Requires @ symbol
  - Shows error if invalid
- ✅ Bank form validates:
  - All fields required
  - Account number length check
  - IFSC code format check
- ✅ Save button works
- ✅ Success message appears
- ✅ Settings persist after reload
- ✅ Can switch between UPI and Bank

**Validation Tests**:
- Try saving empty UPI ID → Error
- Try UPI without @ → Error
- Try short account number → Error
- Try wrong IFSC length → Error

---

### ✅ 6. Dashboard (Tab 1)

**Steps**:
1. Go to Dashboard tab
2. View stats cards
3. Check quick actions
4. View live orders
5. Pull down to refresh

**Expected Result**:
- ✅ Stats cards show:
  - Active listings count
  - Total orders count
  - Pending orders count
  - Revenue amount
- ✅ Quick actions work:
  - Post Harvest
  - Go Live
  - Analytics
- ✅ Live orders stream updates
- ✅ Market status indicator
- ✅ Pull-to-refresh works

---

### ✅ 7. Wallet (Tab 4)

**Steps**:
1. Go to Wallet tab
2. View balance
3. Check stats
4. View transactions
5. Click "Withdraw to UPI / Bank"

**Expected Result**:
- ✅ Available balance displayed
- ✅ Stats show:
  - Total earned
  - This month earnings
  - Orders count
- ✅ Transaction history (if any)
- ✅ Withdraw button present
- ✅ Can navigate to Bank/UPI settings

---

## 🐛 Common Issues & Solutions

### Issue 1: "Could not find farm_address column"
**Solution**: ✅ FIXED - farm_address now included in product model

### Issue 2: "Cannot post product"
**Solution**: 
- Check GPS location is detected
- Ensure at least 1 image is added
- Verify all required fields filled

### Issue 3: "Analytics not loading"
**Solution**:
- Check internet connection
- Verify Supabase connection
- Try pull-to-refresh

### Issue 4: "Reviews not showing"
**Solution**:
- Complete some orders first
- Customers need to leave reviews
- Check database connection

### Issue 5: "Payment settings not saving"
**Solution**:
- Check form validation
- Ensure all required fields filled
- Verify database connection

---

## 📊 Expected Data Flow

### Post Product Flow:
```
1. Farmer fills form
2. Uploads images to Cloudinary
3. Detects GPS location
4. Calculates freshness score
5. Inserts into products table
6. Sends harvest blast notification
7. Nearby customers receive notification
8. Product appears in customer feed
```

### Analytics Flow:
```
1. Load farmer orders from database
2. Load farmer products from database
3. Calculate statistics:
   - Total/completed/pending orders
   - Revenue (sum of completed orders)
   - Active/sold out products
   - Category-wise sales
4. Display in UI with charts
```

### Payment Settings Flow:
```
1. Load existing settings from database
2. Display form based on payment method
3. Validate inputs
4. Save to payment_settings table
5. Show success message
6. Settings available for withdrawals
```

---

## ✅ Success Indicators

### All Features Working If:
- ✅ Can post products without errors
- ✅ Analytics show accurate data
- ✅ Listings display correctly
- ✅ Reviews load (if available)
- ✅ Payment settings save
- ✅ Dashboard stats update
- ✅ Wallet balance shows
- ✅ Navigation smooth
- ✅ No console errors
- ✅ Pull-to-refresh works everywhere

---

## 📸 Screenshot Checklist

Take screenshots of:
1. ✅ Post product screen (filled form)
2. ✅ Post success message
3. ✅ Sales analytics dashboard
4. ✅ My listings with filters
5. ✅ Customer reviews summary
6. ✅ Bank/UPI settings (UPI)
7. ✅ Bank/UPI settings (Bank)
8. ✅ Dashboard with stats
9. ✅ Wallet screen
10. ✅ Profile menu

---

## 🎯 Performance Benchmarks

### Load Times (Should Be):
- Dashboard: < 1 second ✅
- Post Product: < 500ms ✅
- Sales Analytics: < 1 second ✅
- My Listings: < 1 second ✅
- Customer Reviews: < 1 second ✅
- Bank Settings: < 500ms ✅

### Real-Time Updates:
- Order notification: < 2 seconds ✅
- Wallet update: < 1 second ✅
- Dashboard refresh: < 1 second ✅

---

## 🚀 Next Steps After Testing

If all tests pass:
1. ✅ Test on Android device
2. ✅ Test on iOS device
3. ✅ Add more sample data
4. ✅ Test with real orders
5. ✅ Test payment flow
6. ✅ Deploy to production

---

## 📞 Support

If you encounter issues:
1. Check console logs for errors
2. Verify Supabase connection
3. Check database schema
4. Review `FARMER_PANEL_COMPLETE.md`
5. Check `lib/features/farmer/` files

---

**Happy Testing! 🎉**

All farmer panel features are now complete and ready to test!
