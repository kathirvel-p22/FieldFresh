# FieldFresh - Login Credentials

## 🔐 Admin Access (Hidden)

**How to access:**
1. On role selection screen, tap the 🌾 logo 5 times
2. Enter admin code: `admin123`
3. Login with phone: `9999999999`

**Admin Phone:** +919999999999
**Admin Code:** admin123

---

## 👨‍🌾 Farmer Accounts (Demo)

### Farmer 1 - Ramu Farmer
- **Phone:** +919876543210
- **Location:** Chennai (13.0827, 80.2707)
- **Rating:** 4.8⭐
- **Products:** Tomatoes, Spinach, Coconuts

### Farmer 2 - Geetha Devi
- **Phone:** +919876543211
- **Location:** Chennai (13.0927, 80.2807)
- **Rating:** 4.6⭐
- **Products:** Baby Spinach, Drumstick

### Farmer 3 - Muthu Kumar
- **Phone:** +919876543212
- **Location:** Chennai (13.0727, 80.2607)
- **Rating:** 4.9⭐
- **Products:** Organic Mangoes

---

## 🛒 Customer Accounts

**Note:** Any new phone number will create a new customer account

---

## 🚚 Delivery Partner

**Note:** Any new phone number can register as delivery partner

---

## Database Setup

Run this SQL in your Supabase SQL Editor to add the admin user:

```sql
INSERT INTO users (id, phone, name, role, is_verified, rating, created_at) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '+919999999999', 'Admin', 'admin', true, 5.0, NOW())
ON CONFLICT DO NOTHING;
```

---

## Features by Role

### Admin Features:
- View all farmers, customers, orders
- Platform analytics and revenue
- Manage users and products
- Set platform commission rates
- View transaction history

### Farmer Features:
- Post new products with photos
- Manage inventory and pricing
- View and manage orders
- Wallet and earnings tracking
- Live streaming from farm
- Harvest blast notifications

### Customer Features:
- Browse fresh products nearby
- Real-time freshness scores
- Place orders and track delivery
- Group buying for discounts
- Rate farmers and products
- Save favorite farmers

---

## Testing the App

1. **Run the app:** `flutter run -d chrome`
2. **Test farmer login:** Use phone `9876543210`
3. **Test customer:** Use any new phone number
4. **Test admin:** Tap logo 5x, code `admin123`, phone `9999999999`

---

## Important Notes

- **OTP is bypassed for demo** - Existing users login directly
- **New users** will need to complete KYC setup
- **Admin access is hidden** - Only accessible via secret gesture
- **Platform commission:** 5% on all orders (configurable by admin)
