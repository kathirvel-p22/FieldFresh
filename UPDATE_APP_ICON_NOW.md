# Update App Icon - Manual Steps

## The icon files are ready, but the app needs to be reinstalled to show the new icon.

---

## Quick Steps to See New Icon

### Step 1: Uninstall Old App on Emulator

**On the emulator screen:**
1. Find the "fieldfresh" app (with Flutter icon)
2. **Long press** on the app icon
3. Drag it to "Uninstall" at the top
4. Confirm uninstall

### Step 2: Run This Command

In your terminal, run:
```bash
flutter run -d emulator-5554
```

Wait 2-3 minutes for the app to build and install.

### Step 3: Check the New Icon

1. Press Home button on emulator
2. Swipe up to see all apps
3. Look for "fieldfresh"
4. **You'll now see the FreshField logo!** 🎨

---

## Alternative: Build and Install APK

If the emulator isn't detected, try this:

### Step 1: Build APK
```bash
flutter build apk --debug
```

### Step 2: Drag APK to Emulator
1. Find the APK at: `build/app/outputs/flutter-apk/app-debug.apk`
2. Drag and drop it onto the emulator window
3. It will install automatically

### Step 3: Open App
- Swipe up on emulator
- Find "fieldfresh" with new icon
- Tap to open

---

## Why the Icon Didn't Change?

The old app is still installed with the old icon. Android caches app icons, so you need to:
1. **Uninstall the old app** (removes old icon from cache)
2. **Install fresh** (new icon will appear)

---

## Verify Icon Files Are Ready

Run this to confirm icons are in place:
```bash
ls android/app/src/main/res/mipmap-hdpi/ic_launcher.png
```

Should show: `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`

---

## Quick Command

**Uninstall old app and install new:**
```bash
# This will reinstall the app
flutter run -d emulator-5554 --uninstall-first
```

The `--uninstall-first` flag removes the old app before installing.

---

## Your New Icon

After reinstalling, you'll see:
- 🌾 Green farm fields
- 🏠 Red barn  
- 🌞 Yellow sun
- 🥕 Fresh vegetables
- "FreshField" branding

Instead of the blue/white Flutter icon!

---

## Next Steps

1. **Uninstall old app** on emulator (long press → uninstall)
2. **Run:** `flutter run -d emulator-5554`
3. **Enjoy your new icon!** 🎨

The icon is ready and waiting - just needs a fresh install!
