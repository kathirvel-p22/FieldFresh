# Supabase Database Setup Guide

## 🗄️ Complete Database Configuration for FreshField App

This guide will help you set up the PostgreSQL database in Supabase to fix the product posting and other database issues.

---

## 📋 Prerequisites

1. **Supabase Account** - Make sure you have access to your Supabase project
2. **Project URL** - Your Supabase project URL (e.g., `https://your-project.supabase.co`)
3. **API Keys** - Anon key and service role key

---

## 🚀 Step-by-Step Setup

### Step 1: Access Supabase Dashboard
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your FreshField project
4. Go to **SQL Editor** (left sidebar)

### Step 2: Run Database Schema
1. Click **"New Query"** in SQL Editor
2. Copy the entire content from `SUPABASE_DATABASE_SCHEMA.sql`
3. Paste it into the SQL Editor
4. Click **"Run"** button
5. Wait for completion (should show success messages)

### Step 3: Verify Tables Created
After running the schema, you should see these tables in the **Table Editor**:

✅ **Core Tables:**
- `users` - User accounts (farmers, customers, admins)
- `products` - Product listings
- `orders` - Order management
- `reviews` - Customer reviews
- `cart_items` - Shopping cart

✅ **Supporting Tables:**
- `notifications` - Push notifications
- `wallet_transactions` - Payment tracking
- `farmer_followers` - Follow system
- `payment_settings` - Payment methods
- `platform_transactions` - Revenue tracking
- `community_groups` - Group chat
- `group_messages` - Chat messages

### Step 4: Check Table Structure
Click on the `products` table and verify it has these columns:
- `id` (UUID, Primary Key)
- `farmer_id` (UUID, Foreign Key)
- `name` (Text)
- `category` (Text)
- `description` (Text)
- `price_per_unit` (Decimal) ← **This was the missing field!**
- `unit` (Text)
- `quantity_total` (Decimal) ← **This was causing NULL constraint error**
- `quantity_left` (Decimal)
- `image_urls` (Text Array)
- `harvest_time` (Timestamp)
- `valid_until` (Timestamp)
- `freshness_score` (Integer)
- `latitude` (Decimal)
- `longitude` (Decimal)
- `status` (Text)
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

---

## 🔧 Configuration Settings

### Row Level Security (RLS)
The schema enables RLS but with permissive policies for development. For production, you may want to tighten these policies.

### Indexes
Performance indexes are created for:
- User lookups by phone
- Product searches by category and location
- Order queries by customer/farmer
- Notification filtering

### Triggers
Automatic triggers for:
- `updated_at` timestamp updates
- Future: Notification triggers for new products/orders

---

## 🧪 Testing the Setup

### Test 1: Check Tables Exist
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### Test 2: Verify Products Table Structure
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;
```

### Test 3: Insert Test Product
```sql
INSERT INTO products (
    farmer_id, 
    name, 
    category, 
    price_per_unit, 
    unit, 
    quantity_total, 
    quantity_left,
    status
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Test Tomatoes',
    'vegetables',
    50.00,
    'kg',
    10.0,
    10.0,
    'active'
);
```

---

## 🐛 Troubleshooting

### Issue 1: Permission Denied
**Solution**: Make sure you're using the service role key, not the anon key for schema creation.

### Issue 2: Table Already Exists
**Solution**: The schema uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run multiple times.

### Issue 3: UUID Extension Missing
**Solution**: The schema includes `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`

### Issue 4: RLS Blocking Queries
**Solution**: The schema creates permissive policies. You can disable RLS temporarily:
```sql
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
```

---

## 📱 App Configuration

After setting up the database, make sure your app has the correct Supabase configuration:

### lib/services/supabase_service.dart
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### Environment Variables
Create `.env` file:
```
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

---

## ✅ Expected Results

After completing the setup:

1. **Product Posting Works** ✅
   - No more "quantity_total" NULL constraint errors
   - No more "price column not found" errors
   - Images upload successfully

2. **User Registration Works** ✅
   - New users can sign up
   - Profile data saves correctly
   - Admin can see all users

3. **Orders Work** ✅
   - Customers can place orders
   - Farmers receive orders
   - Admin can view all orders

4. **Full App Functionality** ✅
   - All 20 features work
   - Real-time updates
   - Notifications
   - Payment tracking

---

## 🔄 Next Steps

1. **Run the schema** in Supabase SQL Editor
2. **Test product posting** in the app
3. **Verify data appears** in Supabase Table Editor
4. **Test full user flow** (register → post → order → review)
5. **Check admin panel** shows all data

---

## 📊 Database Schema Summary

| Table | Purpose | Key Fields |
|-------|---------|------------|
| users | User accounts | phone, name, role, location |
| products | Product listings | name, price_per_unit, quantity_total |
| orders | Order management | customer_id, farmer_id, status |
| reviews | Customer feedback | rating, comment |
| cart_items | Shopping cart | customer_id, product_id, quantity |
| notifications | Push notifications | user_id, title, message |
| wallet_transactions | Payment tracking | user_id, amount, type |

---

**Status**: ✅ Ready to Deploy  
**Compatibility**: Supabase PostgreSQL 14+  
**App Version**: FreshField 1.2.0

Run the schema and your product posting issues should be resolved! 🚀