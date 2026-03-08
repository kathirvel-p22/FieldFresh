# 📝 FieldFresh - Sign Up Guide

## 🎯 How Sign Up Works

The login screen now handles **both login and signup** automatically!

---

## 🆕 For New Users (Sign Up)

### Step 1: Choose Your Role
- Select **Farmer** 👨‍🌾, **Customer** 🛒, or **Delivery** 🚚

### Step 2: Enter Phone Number
- Enter your 10-digit mobile number
- Example: `9123456789`

### Step 3: Click "Send OTP"
- System checks if number exists
- **If new:** Shows confirmation dialog
- Click "Yes, Sign Up" to create account

### Step 4: Complete Profile (KYC)
- **Name:** Your full name or farm name
- **Address:** Your complete address
- **Location:** Allow GPS access (required)
- **Photo:** Upload profile picture (optional)

### Step 5: Start Using App
- Click "Complete Setup & Start"
- Redirected to your dashboard
- ✅ Account created successfully!

---

## 🔑 For Existing Users (Login)

### Step 1: Choose Your Role
- Select your registered role

### Step 2: Enter Phone Number
- Enter your registered number
- Example: `9876543210`

### Step 3: Click "Send OTP"
- System recognizes your number
- Shows "Welcome back" message
- ✅ Logged in directly to dashboard

---

## 📱 Visual Flow

```
Login Screen
    ↓
Enter Phone Number
    ↓
Click "Send OTP"
    ↓
    ├─→ Number Exists? → Welcome Back → Dashboard
    │
    └─→ New Number? → Confirm Sign Up → KYC Setup → Dashboard
```

---

## 🎨 What You'll See

### On Login Screen:
- ℹ️ **Info Box:** "Existing user? Login directly | New user? We'll create your account"
- 📝 **Sign Up Link:** "New user? Sign Up" (shows help dialog)
- 🔘 **Send OTP Button:** Works for both login and signup

### For New Users:
- 🎉 **Confirmation Dialog:** "Create New Account"
  - Shows your phone number
  - Confirms role (Farmer/Customer/Delivery)
  - "Yes, Sign Up" button

### After Confirmation:
- 📝 **Message:** "Creating your account... Please complete your profile"
- ➡️ **Redirects to:** KYC Setup screen

---

## ✅ Sign Up Features

### Automatic Detection
- ✅ System automatically detects if you're new
- ✅ No separate signup page needed
- ✅ Seamless experience

### Confirmation Dialog
- ✅ Shows phone number for verification
- ✅ Confirms role selection
- ✅ Option to cancel if wrong number

### Profile Setup (KYC)
- ✅ Simple form with 4 fields
- ✅ GPS location auto-detected
- ✅ Photo upload optional
- ✅ Validation for required fields

### Success Messages
- ✅ Clear feedback at each step
- ✅ Welcome messages
- ✅ Error handling

---

## 🧪 Test Sign Up

### Test New Farmer:
1. Select **Farmer** 👨‍🌾
2. Phone: `9111111111` (any new number)
3. Click "Send OTP"
4. Dialog: "Create New Account" → Click "Yes, Sign Up"
5. Fill KYC:
   - Name: "Test Farmer"
   - Address: "Test Farm, Chennai"
   - Allow location
6. Click "Complete Setup"
7. ✅ Farmer Dashboard

### Test New Customer:
1. Select **Customer** 🛒
2. Phone: `9222222222` (any new number)
3. Click "Send OTP"
4. Dialog: "Create New Account" → Click "Yes, Sign Up"
5. Fill KYC:
   - Name: "Test Customer"
   - Address: "Test Address, Chennai"
   - Allow location
6. Click "Complete Setup"
7. ✅ Customer Dashboard

---

## 💡 User Experience

### Clear Indicators:
- 📱 Info box explains the process
- 🔗 "Sign Up" link provides help
- 💬 Confirmation dialog prevents mistakes
- ✅ Success messages confirm actions

### Smart Detection:
- Automatically knows if you're new
- No need to choose "Login" vs "Sign Up"
- One button does everything

### Error Prevention:
- Confirmation before creating account
- Validates phone number format
- Checks for required fields
- Location verification

---

## 🎯 Key Differences

### Login (Existing User):
```
Enter Phone → Send OTP → Welcome Back → Dashboard
```

### Sign Up (New User):
```
Enter Phone → Send OTP → Confirm → KYC Setup → Dashboard
```

---

## 📝 Sign Up Requirements

### Required Information:
- ✅ Phone number (10 digits)
- ✅ Full name
- ✅ Complete address
- ✅ GPS location

### Optional Information:
- 📷 Profile photo
- 📧 Email (future)
- 🏦 Bank details (for farmers, later)

---

## 🔐 Security Features

### Phone Verification:
- Unique phone numbers only
- No duplicate accounts
- Proper validation

### Profile Completion:
- KYC required before access
- Location verification
- Address validation

### Role-Based Access:
- Separate dashboards per role
- Appropriate permissions
- Secure navigation

---

## 🎉 After Sign Up

### Farmers Get:
- Dashboard with stats
- Post products feature
- Order management
- Wallet tracking
- Profile settings

### Customers Get:
- Product browsing
- Shopping cart
- Order tracking
- Favorites
- Profile settings

### Delivery Partners Get:
- Available deliveries
- Route optimization
- Earnings tracker
- Delivery history
- Profile settings

---

## 🐛 Troubleshooting

**Q: I clicked "Send OTP" but nothing happened**
A: Check if you entered a valid 10-digit number

**Q: Dialog doesn't show for new number**
A: Make sure the number is not already registered

**Q: Can't complete KYC setup**
A: Ensure you:
- Fill all required fields
- Allow location access
- Wait for location to be detected

**Q: Want to change phone number**
A: Click "Cancel" in confirmation dialog, then re-enter

**Q: Accidentally created wrong role**
A: Contact admin or create new account with different number

---

## 📞 Support

For any signup issues:
1. Check phone number is correct
2. Ensure location is enabled
3. Fill all required fields
4. Try different browser if issues persist

---

**Ready to sign up? Press `R` in terminal to restart and test!** 🚀
