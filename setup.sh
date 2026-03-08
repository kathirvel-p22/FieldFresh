#!/bin/bash
echo "🌾 FieldFresh — Setup Script"
echo "================================"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Installing..."
    git clone https://github.com/flutter/flutter.git -b stable ~/flutter
    export PATH="$PATH:~/flutter/bin"
    echo 'export PATH="$PATH:~/flutter/bin"' >> ~/.bashrc
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Install dependencies
echo "📦 Installing Flutter packages..."
flutter pub get

echo ""
echo "🔧 CONFIGURATION NEEDED:"
echo "========================="
echo "1. Edit lib/core/constants.dart:"
echo "   - supabaseUrl: Your Supabase project URL"
echo "   - supabaseAnonKey: Your Supabase anon key"
echo "   - razorpayKey: Your Razorpay test key"
echo "   - cloudinaryCloud: Your Cloudinary cloud name"
echo ""
echo "2. Edit lib/firebase_options.dart with your Firebase config"
echo ""
echo "3. Place android/app/google-services.json from Firebase"
echo ""
echo "4. Run Supabase migration:"
echo "   Copy supabase/migrations/001_initial_schema.sql to Supabase SQL editor"
echo ""
echo "5. Setup backend:"
echo "   cd backend && npm install && cp .env.example .env"
echo ""
echo "🚀 Run the app:"
echo "   flutter run              # Android/iOS"
echo "   flutter run -d chrome    # Web"
echo "   flutter build apk        # Build APK"
echo ""
echo "✅ Setup complete!"
