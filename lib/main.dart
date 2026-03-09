import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'firebase_options.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Hive.initFlutter();
  await SupabaseService.initialize();
  
  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized, continue
    debugPrint('Firebase already initialized');
  }
  
  // Skip notification initialization on web (requires service worker setup)
  // TODO: Implement push notification initialization
  // if (!kIsWeb) {
  //   await NotificationService.initialize();
  // }
  
  runApp(const ProviderScope(child: FieldFreshApp()));
}

class FieldFreshApp extends ConsumerWidget {
  const FieldFreshApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
