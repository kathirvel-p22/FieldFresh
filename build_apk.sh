#!/bin/bash

# FreshField APK Build Script
# This script builds the release APK for Android

echo "🌾 FreshField APK Builder"
echo "========================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Build APK
echo "🔨 Building release APK..."
echo "This may take a few minutes..."
echo ""

flutter build apk --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📱 APK Location:"
    echo "   build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📊 APK Size:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print "   " $5}'
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Copy APK to your phone"
    echo "   2. Enable 'Install from Unknown Sources'"
    echo "   3. Install the APK"
    echo "   4. Open FreshField app"
    echo ""
    echo "Or install directly to connected device:"
    echo "   flutter install"
    echo ""
else
    echo ""
    echo "❌ Build failed!"
    echo "Check the error messages above."
    echo ""
    exit 1
fi
