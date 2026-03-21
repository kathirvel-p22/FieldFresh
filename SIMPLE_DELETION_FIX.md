# Simple Fix for Deletion Error

## The Problem
The database has a constraint that prevents certain role values, causing the deletion to fail.

## Simple Solution
Instead of fighting the constraint, let's use a different approach that works with your existing database.

## Step 1: Run This SQL Command
Copy and paste this **single command** into your Supabase SQL Editor:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
```

That's it! Just run that one line.

## Step 2: Test the Deletion
Now try deleting Ramu farmer or Geetha Devi farmer again. It should work!

## How It Works
- The code now uses `is_active = false` instead of changing roles
- This avoids the role constraint completely
- Users with orders get `is_active = false` (soft delete)
- Users without orders get completely deleted (hard delete)
- The admin list only shows users where `is_active` is true or null

## If You Still Get Errors
If you still get errors after running the SQL command, please share the exact error message and I'll provide another solution.

The deletion should work immediately after adding the `is_active` column!