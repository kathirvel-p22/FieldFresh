# 🧪 Progressive Disclosure System - Test Guide

## How to Test the New Privacy System

### 📱 **Setup for Testing**

1. **Run the database setup** (if not done already):
   ```sql
   -- In Supabase SQL Editor, run:
   COMPLETE_DATABASE_FIX_V3.sql
   ```

2. **Start the app**:
   ```bash
   flutter run -d chrome
   ```

3. **Create test accounts**:
   - **Customer**: Use phone `7010773409`
   - **Farmer**: Use phone `7010773410`

### 🔍 **Test Scenarios**

#### **Scenario 1: Product Browsing (Basic Disclosure)**
1. **Login as Customer** (`7010773409`)
2. **Go to Market/Feed**
3. **Expected**: See farmer names and ratings only
4. **Should NOT see**: Phone numbers, addresses, exact locations

#### **Scenario 2: Order Placement (Farmer Gets Limited Info)**
1. **As Customer**: Place an order for "saliya seeds"
2. **Login as Farmer** (`7010773410`)
3. **Go to Orders tab**
4. **Expected**: See customer name only (no phone yet)
5. **Should see message**: "🔒 Customer contact details will be revealed when you confirm the order"

#### **Scenario 3: Order Confirmation (Farmer Gets Customer Phone)**
1. **As Farmer**: Click "Confirm" on the pending order
2. **Expected**: Now see customer phone number
3. **Should see**: Full customer contact details
4. **As Customer**: Still see basic farmer info only

#### **Scenario 4: Packing Stage (Customer Gets Partial Farmer Info)**
1. **As Farmer**: Click "Mark Packed"
2. **As Customer**: Go to "My Orders" → View order details
3. **Expected**: See farmer city and masked phone (e.g., `+91XXXX***XXX`)
4. **Should see message**: "📦 Order is being packed! More details available when dispatched"

#### **Scenario 5: Dispatch (Customer Gets Full Farmer Info)**
1. **As Farmer**: Click "Dispatch"
2. **As Customer**: Check order tracking
3. **Expected**: See full farmer address, exact location, clickable phone
4. **Should see**: "Call Farmer" button is now active
5. **Should see message**: "✅ Full farmer contact details available"

### 🎯 **What to Look For**

#### **Visual Indicators:**
- 🔒 **Lock icon** = Information locked
- 👁️ **Eye icon** = Partial information available  
- ✅ **Check icon** = Full information available

#### **Color Coding:**
- **Yellow/Warning** = Basic disclosure (locked)
- **Blue/Info** = Partial disclosure
- **Green/Success** = Full disclosure

#### **Phone Number Masking:**
- **Before dispatch**: `+91XXXX***XXX` (masked)
- **After dispatch**: `+917010773409` (full number)

#### **Location Information:**
- **Basic**: No location shown
- **Partial**: "📍 Chennai" (city only)
- **Full**: "📍 1/123, North Street, Karur, Tamil Nadu" (complete address)

### 🐛 **Expected Behavior Changes**

#### **Before Implementation:**
- ❌ Customers could see farmer phone immediately
- ❌ Farmers could see customer phone immediately
- ❌ All contact info visible from product browsing

#### **After Implementation:**
- ✅ Progressive information disclosure based on order status
- ✅ Privacy protection until appropriate order stage
- ✅ Clear messaging about when information becomes available
- ✅ Smart contact buttons that adapt to disclosure level

### 📋 **Test Checklist**

#### **Customer Side:**
- [ ] Product browsing shows basic farmer info only
- [ ] Order placement doesn't reveal farmer contact
- [ ] Packing stage shows farmer city + masked phone
- [ ] Dispatch stage shows full farmer location
- [ ] Contact button changes from locked to active
- [ ] Disclosure messages update correctly

#### **Farmer Side:**
- [ ] Pending orders show customer name only
- [ ] Confirmed orders show customer phone
- [ ] Disclosure messages explain when contact is available
- [ ] Customer information progressively revealed

#### **Order Tracking:**
- [ ] Farmer information section shows progressive disclosure
- [ ] Visual indicators (lock/eye/check icons) work
- [ ] Color coding matches disclosure level
- [ ] Contact button adapts to disclosure level

### 🎉 **Success Criteria**

The system is working correctly if:

1. **Privacy is protected** during product browsing
2. **Information is revealed progressively** as order advances
3. **Visual indicators** clearly show disclosure level
4. **Contact buttons** are disabled until appropriate stage
5. **Messages explain** when more information will be available
6. **Phone numbers are masked** until full disclosure
7. **Location information** is limited until dispatch

### 🔧 **Troubleshooting**

If something doesn't work:

1. **Check database setup**: Ensure `COMPLETE_DATABASE_FIX_V3.sql` was run
2. **Refresh the app**: Hot reload may not update all components
3. **Check order status**: Disclosure depends on exact order status
4. **Verify user roles**: Customer vs Farmer disclosure rules are different

---

**Your "saliya seeds" example will now work exactly as requested!** 🌱

The customer will only see full farmer details (location, phone) when the farmer confirms and starts packing the order, providing the perfect balance of privacy and practical communication needs.