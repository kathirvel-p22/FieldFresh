@echo off
REM FreshField APK Build Script for Windows
REM This script builds the release APK for Android

echo.
echo 🌾 FreshField APK Builder
echo =========================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    echo Visit: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version | findstr /C:"Flutter"
echo.

REM Clean previous builds
echo 🧹 Cleaning previous builds...
call flutter clean
echo.

REM Get dependencies
echo 📦 Getting dependencies...
call flutter pub get
echo.

REM Build APK
echo 🔨 Building release APK...
echo This may take a few minutes...
echo.

call flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build successful!
    echo.
    echo 📱 APK Location:
    echo    build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 📊 APK Size:
    dir build\app\outputs\flutter-apk\app-release.apk | findstr "app-release.apk"
    echo.
    echo 🚀 Next Steps:
    echo    1. Copy APK to your phone
    echo    2. Enable 'Install from Unknown Sources'
    echo    3. Install the APK
    echo    4. Open FreshField app
    echo.
    echo Or install directly to connected device:
    echo    flutter install
    echo.
) else (
    echo.
    echo ❌ Build failed!
    echo Check the error messages above.
    echo.
)

pause
