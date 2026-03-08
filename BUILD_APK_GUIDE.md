# Build APK with FreshField Logo

## Step 1: Prepare App Icon

### Option A: Use Online Tool (Easiest)
1. Go to: https://icon.kitchen/
2. Upload your FreshField logo image
3. Select "Android" platform
4. Download the generated icons
5. Extract the zip file

### Option B: Manual Preparation
Create icon sizes:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

## Step 2: Replace App Icons

### For Android:
1. Navigate to: `android/app/src/main/res/`
2. Replace icons in these folders:
   - `mipmap-mdpi/ic_launcher.png`
   - `mipmap-hdpi/ic_launcher.png`
   - `mipmap-xhdpi/ic_launcher.png`
   - `mipmap-xxhdpi/ic_launcher.png`
   - `mipmap-xxxhdpi/ic_launcher.png`

### For Web (Chrome):
1. Create `web/icons/` folder if it doesn't exist
2. Add these icon sizes:
   - `Icon-192.png` (192x192)
   - `Icon-512.png` (512x512)
   - `Icon-maskable-192.png` (192x192)
   - `Icon-maskable-512.png` (512x512)

## Step 3: Update Web Manifest

Edit `web/manifest.json`:

```json
{
  "name": "FreshField",
  "short_name": "FreshField",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#4CAF50",
  "description": "Farm-to-Table Fresh Produce Platform",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
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
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

## Step 4: Update App Name

### Android App Name:
Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="FreshField"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

### iOS App Name (if needed):
Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleName</key>
<string>FreshField</string>
<key>CFBundleDisplayName</key>
<string>FreshField</string>
```

## Step 5: Build APK

### Clean Build:
```bash
flutter clean
flutter pub get
```

### Build APK:
```bash
flutter build apk --release
```

### Build Split APKs (smaller size):
```bash
flutter build apk --split-per-abi --release
```

This creates 3 APKs:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

### Build for Web:
```bash
flutter build web --release
```

## Step 6: Find Your APK

APK location:
```
build/app/outputs/flutter-apk/app-release.apk
```

Or for split APKs:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

Web build location:
```
build/web/
```

## Step 7: Test APK

### Install on Android Device:
```bash
flutter install
```

Or manually:
1. Copy APK to phone
2. Enable "Install from Unknown Sources"
3. Tap APK to install

### Test on Chrome:
```bash
flutter run -d chrome --release
```

Or serve the web build:
```bash
cd build/web
python -m http.server 8000
```
Then open: http://localhost:8000

## Step 8: Sign APK (Production)

### Generate Keystore:
```bash
keytool -genkey -v -keystore freshfield-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias freshfield
```

### Create key.properties:
Create `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=freshfield
storeFile=../freshfield-key.jks
```

### Update build.gradle:
Edit `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Build Signed APK:
```bash
flutter build apk --release
```

## Troubleshooting

### Icon Not Showing:
- Clear app data and reinstall
- Check icon file names match exactly
- Verify icon sizes are correct

### Build Fails:
```bash
flutter clean
flutter pub get
flutter build apk --release --verbose
```

### Web Icons Not Showing:
- Clear browser cache
- Check manifest.json paths
- Verify icon files exist in web/icons/

## APK Size Optimization

### Reduce APK Size:
```bash
flutter build apk --release --shrink --split-per-abi
```

### Enable Obfuscation:
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

## Distribution

### Share APK:
1. Upload to Google Drive
2. Share link with users
3. Users download and install

### Publish to Play Store:
1. Create Google Play Console account
2. Create app listing
3. Upload signed APK
4. Fill in store details
5. Submit for review

## Quick Commands

```bash
# Clean and build
flutter clean && flutter pub get && flutter build apk --release

# Build for web
flutter build web --release

# Install on connected device
flutter install

# Run on Chrome
flutter run -d chrome --release
```

## Expected Output

After successful build:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

Your APK is ready to install and distribute!
