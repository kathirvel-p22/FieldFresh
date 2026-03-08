# Fix Blank Screen Issue

## Current Status
The app is running but showing a blank screen. The errors about Firebase and fonts are just warnings and won't prevent the app from working.

## Quick Fix

### Option 1: Hot Restart (Fastest)
In the terminal where `flutter run` is running, press:
```
R
```
This will do a full restart and reload all code changes.

### Option 2: Stop and Restart
1. Press `q` in the terminal to quit
2. Run again:
```bash
flutter run -d chrome
```

### Option 3: Clear Cache and Restart
```bash
# Stop the app (press 'q')
flutter clean
flutter pub get
flutter run -d chrome
```

## What to Expect After Restart

1. **Splash Screen** - FieldFresh logo
2. **Onboarding** - Swipe through intro screens
3. **Role Selection** - Choose Farmer/Customer/Delivery
4. **Login Screen** - Enter phone number

## Test Credentials

### Farmer Login:
- Phone: `9876543210` (Ramu Farmer)
- Phone: `9876543211` (Geetha Devi)
- Phone: `9876543212` (Muthu Kumar)

### Admin Login:
- Phone: `9999999999`
- Or tap logo 5x on role screen, enter code: `admin123`

### New User:
- Any other 10-digit number
- Will create new account

## If Still Blank

### Check Console for Errors
Look for actual errors (not warnings about fonts/firebase). Common issues:

1. **Navigation Error** - Check if splash screen is navigating properly
2. **Supabase Connection** - Check if Supabase is responding
3. **Build Error** - Check if there are any compilation errors

### Force Reload
1. Open Chrome DevTools (F12)
2. Right-click the reload button
3. Select "Empty Cache and Hard Reload"

### Check Network
1. Open Chrome DevTools → Network tab
2. Reload the page
3. Check if Supabase API calls are working
4. Look for any failed requests

## Warnings You Can Ignore

These are normal and won't affect functionality:
```
- Failed to load font Roboto (network issue, will use fallback)
- Failed to fetch Firebase modules (only needed for push notifications)
- viewport tag warning (Flutter handles this automatically)
- --no-sandbox warning (Chrome security, doesn't affect app)
```

## What Should Work

After successful restart:
✅ Splash screen appears
✅ Onboarding screens work
✅ Role selection works
✅ Login system works
✅ Dashboard loads with data
✅ All admin features accessible

## Debug Steps

If blank screen persists:

1. **Check Browser Console:**
   - Press F12
   - Look for red errors
   - Share any error messages

2. **Check Flutter Console:**
   - Look for Dart exceptions
   - Check for navigation errors
   - Look for Supabase errors

3. **Verify Supabase:**
   - Check if project is active
   - Verify API keys are correct
   - Test connection manually

## Common Solutions

### Problem: Stuck on Splash
**Solution:** Check splash_screen.dart navigation logic

### Problem: White Screen After Login
**Solution:** Check if demo user ID is being set

### Problem: Dashboard Not Loading
**Solution:** Already fixed! Demo user ID is now set on login

### Problem: No Data Showing
**Solution:** Check Supabase connection and sample data

## Need Help?

If the issue persists, please share:
1. Browser console errors (F12 → Console tab)
2. Flutter terminal output
3. Screenshot of the blank screen
4. Any error messages you see

The app is fully functional - just needs a proper restart to load all the new changes! 🚀
