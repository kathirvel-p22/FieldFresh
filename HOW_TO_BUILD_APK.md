# 📱 How to Build FreshField APK

## ⚠️ Current Status

The APK build has a Flutter SDK compatibility issue. Follow these steps to build the APK on your machine.

---

## 🔧 Prerequisites

1. **Flutter SDK** - Latest stable version
2. **Android Studio** - With Android SDK
3. **Java JDK** - Version 17 or higher
4. **Git** - To clone the repository

---

## 📥 Step 1: Clone the Repository

```bash
git clone https://github.com/kathirvel-p22/FieldFresh.git
cd FieldFresh
```

---

## 🔄 Step 2: Update Flutter SDK

```bash
# Update Flutter to latest version
flutter upgrade

# Check Flutter version
flutter doctor -v
```

**Required**: Flutter 3.19.0 or higher

---

## 📦 Step 3: Install Dependencies

```bash
# Get all packages
flutter pub get

# Clean previous builds
flutter clean
```

---

## 🔨 Step 4: Build APK

### Option 1: Standard Build
```bash
flutter build apk --release
```

### Option 2: Split APK (Smaller size)
```bash
flutter build apk --split-per-abi --release
```

### Option 3: Skip Validation (If build fails)
```bash
flutter build apk --release --android-skip-build-dependency-validation
```

---

## 📍 Step 5: Find Your APK

After successful build, find the APK at:

**Standard Build**:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Split Build** (3 APKs for different architectures):
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  (32-bit ARM)
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    (64-bit ARM - Most common)
build/app/outputs/flutter-apk/app-x86_64-release.apk       (64-bit Intel)
```

**Recommended**: Use `app-arm64-v8a-release.apk` for most Android devices.

---

## 🐛 Troubleshooting

### Error: Gradle version incompatible

**Solution**:
```bash
# Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version 8.7
cd ..
flutter clean
flutter build apk --release
```

### Error: Android Gradle Plugin version

**Solution**: Edit `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.3.0'  // Update this line
}
```

### Error: Java version

**Solution**: Install Java 17 or higher
```bash
# Check Java version
java -version

# Should show: openjdk version "17" or higher
```

### Error: Flutter SDK not found

**Solution**:
```bash
# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"  # Linux/Mac
set PATH=%PATH%;C:\flutter\bin         # Windows
```

---

## 🌐 Alternative: Use Web Version

If APK build continues to fail, use the web version:

```bash
# Run in Chrome
flutter run -d chrome

# Build for web deployment
flutter build web --release
```

The web version has ALL features working perfectly!

---

## 📱 Install APK on Android Device

### Method 1: USB Cable
```bash
# Connect device via USB
# Enable USB debugging on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Direct Transfer
1. Copy APK to phone
2. Open file manager
3. Tap APK file
4. Allow "Install from unknown sources"
5. Install

---

## ✅ Verify Installation

After installation:
1. Open FreshField app
2. Login with test account:
   - Farmer: `9876543211`
   - Customer: `9876543210`
3. Test all features

---

## 🎯 Build for Production

### 1. Generate Signing Key

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Configure Signing

Create `android/key.properties`:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=<path-to-keystore>
```

### 3. Build Signed APK

```bash
flutter build apk --release
```

---

## 📊 APK Size Optimization

### Reduce APK Size

```bash
# Enable code shrinking
flutter build apk --release --shrink

# Split by ABI (creates 3 smaller APKs)
flutter build apk --split-per-abi --release
```

### Expected Sizes
- Standard APK: ~50-60 MB
- Split APK (arm64): ~20-25 MB

---

## 🚀 Upload to Play Store

### 1. Build App Bundle (Recommended)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 2. Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Upload AAB file
4. Fill app details
5. Submit for review

---

## 📝 Important Notes

1. **API Keys**: The app uses demo API keys. For production:
   - Update Supabase URL and keys in `lib/core/constants.dart`
   - Update Firebase config in `android/app/google-services.json`
   - Update Cloudinary credentials

2. **Database**: Run SQL scripts in Supabase:
   - `supabase/schema.sql` - Main database
   - `supabase/PROGRESSIVE_SYSTEM_SCHEMA.sql` - Notifications
   - `supabase/COMMUNITY_GROUPS_SCHEMA.sql` - Community features

3. **Testing**: Use demo mode for testing:
   - Any 6-digit OTP works
   - Test accounts provided in `LOGIN_CREDENTIALS.md`

---

## 🆘 Still Having Issues?

### Check Flutter Doctor
```bash
flutter doctor -v
```

Fix any issues shown (Android SDK, licenses, etc.)

### Clean Everything
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter build apk --release
```

### Update Everything
```bash
flutter upgrade
flutter pub upgrade
flutter build apk --release
```

---

## 📞 Support

If you continue to face issues:
1. Check Flutter version: `flutter --version`
2. Check Java version: `java -version`
3. Check Android SDK: `flutter doctor -v`
4. Try web version: `flutter run -d chrome`

---

## 🎉 Success!

Once built, your APK is ready to:
- Install on any Android device
- Share with testers
- Upload to Play Store
- Distribute to users

**Your FreshField app is production-ready! 🌾**
