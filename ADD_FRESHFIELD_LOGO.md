# Add FreshField Logo to App

## Quick Steps

### 1. Prepare Your Logo
- Create a square logo image (1024x1024 recommended)
- Save as PNG with transparent background
- Name it `freshfield_logo.png`

### 2. Generate App Icons (Easiest Method)

#### Using Icon Kitchen (Recommended):
1. Go to: https://icon.kitchen/
2. Click "Upload Image"
3. Upload your `freshfield_logo.png`
4. Select platforms:
   - ✅ Android
   - ✅ iOS
   - ✅ Web
5. Click "Download"
6. Extract the zip file

#### Using Flutter Launcher Icons (Alternative):
```bash
# Add to pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/freshfield_logo.png"
  adaptive_icon_background: "#4CAF50"
  adaptive_icon_foreground: "assets/freshfield_logo.png"

# Run generator
flutter pub get
flutter pub run flutter_launcher_icons
```

### 3. Replace Android Icons

Copy icons to these folders:
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
└── mipmap-xxxhdpi/ic_launcher.png (192x192)
```

### 4. Replace iOS Icons (if building for iOS)

Copy icons to:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

### 5. Replace Web Icons

Create `web/icons/` folder and add:
```
web/icons/
├── Icon-192.png (192x192)
├── Icon-512.png (512x512)
├── Icon-maskable-192.png (192x192)
└── Icon-maskable-512.png (512x512)
```

Update `web/manifest.json`:
```json
{
  "name": "FreshField",
  "short_name": "FreshField",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### 6. Update App Name

#### Android:
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="FreshField"
    android:icon="@mipmap/ic_launcher">
```

#### iOS:
Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleName</key>
<string>FreshField</string>
```

### 7. Build APK

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release
```

### 8. Verify Logo

1. Install APK on phone
2. Check home screen icon
3. Check app drawer icon
4. Check recent apps icon

## Manual Icon Creation (If Needed)

### Using GIMP (Free):
1. Open your logo in GIMP
2. Image → Scale Image
3. Set width and height (e.g., 192x192)
4. Export as PNG
5. Repeat for all sizes

### Using Photoshop:
1. Open logo
2. Image → Image Size
3. Set dimensions
4. Save for Web (PNG-24)
5. Repeat for all sizes

### Using Online Tools:
- https://resizeimage.net/
- https://www.iloveimg.com/resize-image
- https://www.img2go.com/resize-image

## Icon Sizes Reference

### Android:
- mdpi: 48x48
- hdpi: 72x72
- xhdpi: 96x96
- xxhdpi: 144x144
- xxxhdpi: 192x192

### iOS:
- 20x20, 29x29, 40x40, 58x58, 60x60, 76x76, 80x80, 87x87, 120x120, 152x152, 167x167, 180x180, 1024x1024

### Web:
- 192x192 (standard)
- 512x512 (high-res)

## Troubleshooting

### Icon not showing after install:
```bash
# Uninstall old app
adb uninstall com.fieldfresh.app

# Rebuild and install
flutter clean
flutter build apk --release
flutter install
```

### Icon looks blurry:
- Use higher resolution source image (1024x1024)
- Ensure PNG has transparent background
- Use proper scaling tools

### Wrong icon showing:
- Clear app cache
- Restart device
- Check icon file names match exactly

## Quick Command Summary

```bash
# 1. Clean
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build APK
flutter build apk --release

# 4. Install on device
flutter install

# 5. Build for web
flutter build web --release
```

## Expected Result

After following these steps:
- ✅ FreshField logo appears on home screen
- ✅ Logo shows in app drawer
- ✅ Logo displays in recent apps
- ✅ Logo appears in Chrome tab (web)
- ✅ Logo shows in PWA install prompt

Your app now has the FreshField branding!
