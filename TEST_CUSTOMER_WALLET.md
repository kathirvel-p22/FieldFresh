# Test Customer Wallet - Quick Guide

## Quick Test (3 Minutes)

### Step 1: Login as Customer
- Phone: +919894768404 or 9876543210
- OTP: any 6 digits

### Step 2: Go to Wallet Tab
- Click "Wallet" tab (4th tab in bottom navigation)
- You should see:
  - ✅ Bank accounts with balances
  - ✅ Spending stats (Total Spent, This Month, Orders)
  - ✅ Transaction history

### Step 3: Check Bank Balance
- View your bank account card
- Should show: ₹5000.00 (demo balance)
- Or less if you've made purchases

### Step 4: Make a Test Purchase
1. Go to "Market" tab
2. Click any product
3. Click "Add to Cart"
4. Go to cart (top right icon)
5. Click "Proceed to Checkout"
6. Select your bank account
7. Enter delivery address (or leave default)
8. Click "Pay ₹XXX"
9. Enter PIN: any 4 digits (first time will ask to set PIN)
10. Payment successful!

### Step 5: Check Wallet Again
1. Go back to "Wallet" tab
2. Pull down to refresh
3. You should see:
   - ✅ Bank balance reduced by purchase amount
   - ✅ New transaction in history
   - ✅ Total spent increased
   - ✅ Order count increased

## What You'll See

### Bank Account Card:
```
┌─────────────────────────────┐
│ State Bank of India    PRIMARY│
│ ****1234                     │
│                              │
│ Available Balance            │
│ ₹4655.00                     │
└─────────────────────────────┘
```

### Spending Stats:
```
┌─────────┐ ┌─────────┐ ┌─────────┐
│ 🛒      │ │ 📅      │ │ 🧾      │
│ ₹345    │ │ ₹345    │ │ 1       │
│ Total   │ │ This    │ │ Orders  │
│ Spent   │ │ Month   │ │         │
└─────────┘ └─────────┘ └─────────┘
```

### Transaction History:
```
❌ Tomatoes
   2 kg
   2h ago
   -₹345

❌ Onions  
   1 kg
   5h ago
   -₹200
```

## Features to Test

### 1. Multiple Bank Accounts
- Click "Add" button in wallet
- Add another bank account
- Set one as primary
- Use different accounts for purchases

### 2. Spending Tracking
- Make multiple purchases
- Check "Total Spent" increases
- Check "This Month" updates
- Check "Orders" count increases

### 3. Transaction Details
- Each transaction shows:
  - Product name
  - Quantity and unit
  - Amount deducted (red, with -)
  - Time ago

### 4. Balance Verification
- Try to buy something expensive (>₹5000)
- Should show "Insufficient balance" error
- No money deducted

### 5. Real-time Updates
- Make a purchase
- Go to wallet
- Pull down to refresh
- Balance updates immediately

## Payment Flow

```
1. Add to Cart → 2. Checkout → 3. Select Bank → 4. Enter PIN → 5. Pay
                                                                    ↓
6. Wallet Updates ← 5. Transaction Recorded ← 4. Balance Deducted ←
```

## Expected Results

### After First Purchase (₹345):
- Bank Balance: ₹5000 - ₹345 = ₹4655
- Total Spent: ₹345
- This Month: ₹345
- Orders: 1
- Transaction History: 1 item

### After Second Purchase (₹200):
- Bank Balance: ₹4655 - ₹200 = ₹4455
- Total Spent: ₹545
- This Month: ₹545
- Orders: 2
- Transaction History: 2 items

## Troubleshooting

### Wallet shows ₹0 balance?
- Pull down to refresh
- Check if bank account is added
- Go to "Add Bank Account" if needed

### No transactions showing?
- Make sure you've completed a purchase
- Pull down to refresh
- Check Orders tab to confirm delivery

### Payment fails?
- Check bank balance is sufficient
- Verify PIN is correct (4 digits)
- Try refreshing wallet

## All Working! ✅

- Bank account balances tracked
- Automatic deductions on purchase
- Transaction history recorded
- Spending stats calculated
- Real-time updates
- Secure PIN-based payments
