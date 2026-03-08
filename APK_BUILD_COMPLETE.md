# APK Build Complete Guide ✅

## What You Need to Do

### 1. Add FreshField Logo (5 minutes)

#### Quick Method:
1. Go to: https://icon.kitchen/
2. Upload your FreshField logo
3. Select Android + iOS + Web
4. Download icons
5. Replace icons in project folders

See detailed steps in: `ADD_FRESHFIELD_LOGO.md`

### 2. Build APK (2 minutes)

#### Windows:
```bash
# Double-click this file:
build_apk.bat
```

#### Mac/Linux:
```bash
# Run this command:
chmod +x build_apk.sh
./build_apk.sh
```

#### Manual Build:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 3. Find Your APK

Location:
```
build/app/outputs/flutter-apk/app-release.apk
```

Size: ~50MB

### 4. Install APK

#### On Phone:
1. Copy APK to phone
2. Settings → Security → Enable "Unknown Sources"
3. Open APK file
4. Tap "Install"
5. Open FreshField app

#### Via USB:
```bash
flutter install
```

### 5. Test on Chrome

```bash
flutter run -d chrome --release
```

Or build web version:
```bash
flutter build web --release
```

Web files location: `build/web/`

## Files Created

1. `BUILD_APK_GUIDE.md` - Complete APK build guide
2. `ADD_FRESHFIELD_LOGO.md` - Logo replacement guide
3. `build_apk.sh` - Linux/Mac build script
4. `build_apk.bat` - Windows build script
5. `README.md` - Updated with APK download links

## Quick Commands

### Build APK:
```bash
flutter build apk --release
```

### Build Split APKs (smaller):
```bash
flutter build apk --split-per-abi --release
```

### Build for Web:
```bash
flutter build web --release
```

### Install on Device:
```bash
flutter install
```

### Run on Chrome:
```bash
flutter run -d chrome
```

## Icon Locations

### Android Icons:
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png
├── mipmap-hdpi/ic_launcher.png
├── mipmap-xhdpi/ic_launcher.png
├── mipmap-xxhdpi/ic_launcher.png
└── mipmap-xxxhdpi/ic_launcher.png
```

### Web Icons:
```
web/icons/
├── Icon-192.png
├── Icon-512.png
├── Icon-maskable-192.png
└── Icon-maskable-512.png
```

## App Name

Current: "FreshField"

To change, edit:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `web/manifest.json`

## Distribution

### Share APK:
1. Upload to Google Drive
2. Share link with users
3. Users download and install

### Publish to Play Store:
1. Create Google Play Console account ($25 one-time)
2. Create app listing
3. Upload signed APK
4. Fill in store details
5. Submit for review

## Troubleshooting

### Build Fails:
```bash
flutter clean
flutter pub get
flutter doctor
flutter build apk --release --verbose
```

### Icon Not Showing:
- Uninstall old app
- Clear cache
- Reinstall APK

### APK Too Large:
```bash
flutter build apk --split-per-abi --release
```

This creates 3 smaller APKs:
- ARM64 (most phones)
- ARM32 (older phones)
- x86 (emulators)

## Expected Output

After successful build:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (50.2MB)
```

## Next Steps

1. ✅ Add FreshField logo
2. ✅ Build APK
3. ✅ Test on phone
4. ✅ Share with users
5. ✅ Deploy web version
6. ✅ Publish to Play Store (optional)

## Support

For issues:
1. Check `BUILD_APK_GUIDE.md`
2. Check `ADD_FRESHFIELD_LOGO.md`
3. Run `flutter doctor`
4. Check Flutter documentation

## Summary

You now have:
- ✅ Complete APK build guide
- ✅ Logo replacement instructions
- ✅ Build scripts (Windows + Mac/Linux)
- ✅ Updated README with download links
- ✅ Web build instructions
- ✅ Distribution guide

Just add your FreshField logo and run the build script!
