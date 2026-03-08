# FieldFresh - Complete Authentication System

## 🔐 Authentication Flow

### 1. **Splash Screen** → Auto-navigation
- Shows FieldFresh logo with animation
- Checks if user is already logged in
- Routes to appropriate screen based on auth state

### 2. **Onboarding** → First-time users
- 4 slides explaining app features
- Skip or swipe through
- Ends with "Get Started" button

### 3. **Role Selection** → Choose user type
- **Farmer** 👨‍🌾 - Sell produce
- **Customer** 🛒 - Buy produce  
- **Delivery Partner** 🚚 - Deliver orders
- **Admin** 🔐 - Hidden (tap logo 5 times, code: `admin123`)

### 4. **Login Screen** → Phone number entry
- Enter 10-digit mobile number
- System checks if user exists
- Two paths:
  - **Existing User** → Direct login (demo mode)
  - **New User** → Create account → KYC setup

### 5. **KYC Setup** → Complete profile (New users only)
- Upload profile photo (optional)
- Enter name/farm name
- Enter address
- Auto-detect GPS location
- Complete setup → Dashboard

---

## 📱 User Registration Flow

```
New User Journey:
1. Select Role (Farmer/Customer/Delivery)
2. Enter Phone Number
3. System creates basic user record
4. Complete KYC Profile:
   - Name
   - Address
   - Location (GPS)
   - Profile Photo (optional)
5. Navigate to Dashboard
```

---

## 🔑 Login Flow

```
Existing User Journey:
1. Select Role
2. Enter Phone Number
3. System checks database
4. If KYC complete → Direct to Dashboard
5. If KYC incomplete → Complete KYC first
```

---

## 👥 User Roles & Dashboards

### Farmer Dashboard
- Post new products
- Manage inventory
- View orders
- Wallet & earnings
- Live streaming
- Analytics

### Customer Dashboard
- Browse products
- Search by category
- View freshness scores
- Place orders
- Track deliveries
- Group buying

### Admin Dashboard
- View all users
- Manage farmers & customers
- Platform analytics
- Revenue tracking
- Order management
- System settings

---

## 🧪 Testing Accounts

### Demo Farmer Accounts (Already in Database)
```
Phone: 9876543210
Name: Ramu Farmer
Status: KYC Complete
```

```
Phone: 9876543211
Name: Geetha Devi
Status: KYC Complete
```

```
Phone: 9876543212
Name: Muthu Kumar
Status: KYC Complete
```

### Admin Account
```
Phone: 9999999999
Name: Admin
Access: Tap logo 5x, code: admin123
Status: KYC Complete
```

### New User Testing
- Use any other 10-digit number
- Will create new account
- Must complete KYC setup

---

## 🔧 Technical Implementation

### Database Tables
- **users** - User profiles and authentication
- **products** - Farmer products
- **orders** - Customer orders
- **farmer_wallets** - Farmer earnings
- **notifications** - Push notifications

### Authentication Method (Current)
- **Demo Mode**: Phone-based lookup (no OTP)
- **Production Ready**: Supabase Auth with SMS OTP (commented out)

### Security Features
- Role-based access control (RLS policies)
- Hidden admin access
- Location verification
- KYC validation

---

## 🚀 How to Test

### Test Existing User Login:
1. Run app: `flutter run -d chrome`
2. Select "Farmer" role
3. Enter: `9876543210`
4. Click "Send OTP"
5. ✅ Logs in directly to Farmer Dashboard

### Test New User Registration:
1. Select "Customer" role
2. Enter any new number: `9123456789`
3. Click "Send OTP"
4. Complete KYC form:
   - Name: "Test Customer"
   - Address: "123 Test Street"
   - Allow location access
5. Click "Complete Setup"
6. ✅ Navigates to Customer Dashboard

### Test Admin Access:
1. On role selection screen
2. Tap 🌾 logo 5 times quickly
3. Enter code: `admin123`
4. Enter phone: `9999999999`
5. ✅ Logs in to Admin Dashboard

---

## 📊 Database Setup

Run this in Supabase SQL Editor to add admin:

```sql
INSERT INTO users (id, phone, name, role, is_verified, is_kyc_done, rating, created_at) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '+919999999999', 'Admin', 'admin', true, true, 5.0, NOW())
ON CONFLICT DO NOTHING;
```

---

## 🔄 Switching to Production OTP

To enable real SMS OTP (production):

1. **Enable Supabase Phone Auth:**
   - Go to Supabase Dashboard → Authentication → Providers
   - Enable "Phone" provider
   - Configure Twilio/MessageBird

2. **Update login_screen.dart:**
   - Uncomment OTP sending code
   - Remove direct login bypass

3. **Update otp_screen.dart:**
   - Already configured for OTP verification
   - Will work automatically once Supabase Auth is enabled

---

## 🎯 Features by Role

### Farmer Features:
✅ Post products with photos
✅ Set prices and quantities
✅ Manage orders
✅ View earnings
✅ Wallet management
✅ Live streaming
✅ Harvest blast notifications

### Customer Features:
✅ Browse nearby products
✅ Real-time freshness scores
✅ Place orders
✅ Track deliveries
✅ Group buying
✅ Rate farmers
✅ Save favorites

### Admin Features:
✅ User management
✅ Platform analytics
✅ Revenue tracking
✅ Order oversight
✅ Commission settings
✅ System monitoring

---

## 📝 Notes

- **Current Mode**: Demo (no real OTP for testing)
- **Location**: Required for farmers and customers
- **Photos**: Optional but recommended
- **Platform Fee**: 5% on all orders (admin configurable)
- **Payment**: Razorpay integration (test mode)

---

## 🐛 Troubleshooting

**Issue**: Back button not working
**Fix**: ✅ Fixed - uses `context.go()` instead of `context.pop()`

**Issue**: Login error
**Fix**: Check if user exists in database, complete KYC if needed

**Issue**: Location not detected
**Fix**: Allow location permissions in browser/device settings

**Issue**: Can't access admin
**Fix**: Tap logo 5 times, use code `admin123`, phone `9999999999`

---

## 🎉 Ready to Test!

Your complete authentication system is now set up with:
- ✅ Role-based login
- ✅ New user registration
- ✅ KYC profile setup
- ✅ Hidden admin access
- ✅ Dashboard navigation
- ✅ Demo accounts ready

Press `R` in terminal to restart the app and test!
