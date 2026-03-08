// REPLACE with your actual Firebase config from Firebase Console
// Run: flutterfire configure  (after installing flutterfire_cli)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('No Firebase options for ${defaultTargetPlatform.name}');
    }
  }

  // Firebase configuration for FieldFresh project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC828lutW_GLPZ4ZU6YGTJd7jJ-2hWwLww',
    appId: '1:976329464793:web:YOUR_WEB_APP_ID',
    messagingSenderId: '976329464793',
    projectId: 'fieldfresh-77ae2',
    authDomain: 'fieldfresh-77ae2.firebaseapp.com',
    storageBucket: 'fieldfresh-77ae2.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC828lutW_GLPZ4ZU6YGTJd7jJ-2hWwLww',
    appId: '1:976329464793:android:5419e71fc65ec0c5da97c8',
    messagingSenderId: '976329464793',
    projectId: 'fieldfresh-77ae2',
    storageBucket: 'fieldfresh-77ae2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC828lutW_GLPZ4ZU6YGTJd7jJ-2hWwLww',
    appId: '1:976329464793:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '976329464793',
    projectId: 'fieldfresh-77ae2',
    storageBucket: 'fieldfresh-77ae2.firebasestorage.app',
    iosBundleId: 'com.fieldfresh.app',
  );
}
