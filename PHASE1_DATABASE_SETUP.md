# 🗄️ Phase 1: Database Setup - Community Groups

## ✅ What This Creates

### 5 New Tables
1. **group_categories** - Categories like Organic, Vegetables, Dairy
2. **community_groups** - The groups themselves
3. **group_members** - Who's in which group
4. **group_messages** - All chat messages
5. **group_invites** - Pending invitations

### Features
- ✅ Automatic member count updates
- ✅ Automatic message count updates
- ✅ Indexes for fast queries
- ✅ Sample data (10 categories, 10 groups)
- ✅ Triggers for real-time updates

## 🚀 How to Run

### Step 1: Open Supabase SQL Editor
1. Go to https://supabase.com/dashboard
2. Select your project
3. Click "SQL Editor" (left sidebar)
4. Click "+ New Query"

### Step 2: Copy & Paste SQL
Open the file: `supabase/COMMUNITY_GROUPS_SCHEMA.sql`

Copy the entire content and paste it into the SQL editor

### Step 3: Run
Click "Run" button (or Ctrl+Enter)

### Step 4: Verify
You should see output showing:
- ✅ Tables created
- ✅ Sample categories (10 items)
- ✅ Sample groups (10 items)
- ✅ Indexes created

## 📊 What You Get

### Sample Categories
```
🌱 Organic Farming
🥬 Vegetables
🍎 Fruits
🥛 Dairy
💰 Market Tips
🚜 Equipment
🌾 Seeds
🐛 Pest Control
🌤️ Weather
🍳 Recipes
```

### Sample Groups
```
1. Organic Tomato Growers (45 members)
2. Chennai Farmers Network (128 members)
3. Dairy Farming Best Practices (67 members)
4. Fresh Fruit Lovers (89 members)
5. Natural Pest Control (34 members)
6. Farm Equipment Exchange (56 members)
7. Organic Certification Help (23 members)
8. Seasonal Farming Tips (91 members)
9. Farm-to-Table Recipes (112 members)
10. Weather & Farming (78 members)
```

## 🔍 Database Structure

### community_groups table
```
- id (UUID)
- name (text)
- description (text)
- category (text)
- image_url (text)
- creator_id (UUID → users)
- member_count (integer)
- message_count (integer)
- is_public (boolean)
- is_active (boolean)
- created_at (timestamp)
- updated_at (timestamp)
```

### group_members table
```
- id (UUID)
- group_id (UUID → community_groups)
- user_id (UUID → users)
- role (text: admin/moderator/member)
- is_muted (boolean)
- joined_at (timestamp)
- last_read_at (timestamp)
```

### group_messages table
```
- id (UUID)
- group_id (UUID → community_groups)
- user_id (UUID → users)
- user_name (text)
- user_role (text: farmer/customer/admin)
- message (text)
- message_type (text: text/image/contact/system)
- image_url (text)
- metadata (jsonb)
- is_deleted (boolean)
- created_at (timestamp)
```

## ✅ After Running SQL

You'll have:
- ✅ Complete database structure
- ✅ 10 sample groups ready to use
- ✅ 10 categories for organizing groups
- ✅ Automatic counters (members, messages)
- ✅ Indexes for fast performance
- ✅ Ready for Phase 2 (UI implementation)

## 🎯 Next Steps

After database is set up:
1. ✅ Phase 1 Complete - Database ready
2. ⏳ Phase 2 - Implement basic UI (groups list + chat)
3. ⏳ Phase 3 - Full features (create, manage, notifications)

## 🐛 Troubleshooting

### Error: "relation already exists"
**Solution**: Tables already created, you're good!

### Error: "permission denied"
**Solution**: Make sure you're logged into Supabase dashboard

### No sample data showing
**Solution**: Run the INSERT statements separately

## 📝 Files Created

- `supabase/COMMUNITY_GROUPS_SCHEMA.sql` - Complete database schema
- `PHASE1_DATABASE_SETUP.md` - This guide

**Run the SQL now to complete Phase 1!** 🚀
