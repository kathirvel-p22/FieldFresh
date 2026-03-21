import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'services/connection_test_service.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Language Service
  final languageService = await LanguageService.initialize();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Authentication Service
  await AuthService.initialize();
  
  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized, continue
    debugPrint('Firebase already initialized');
  }
  
  // Test database connection instead of enterprise services
  try {
    final connectionStatus = await ConnectionTestService.getConnectionStatus();
    debugPrint('📊 Connection Status: $connectionStatus');
    
    if (connectionStatus['connected']) {
      debugPrint('✅ Database connection successful');
    } else {
      debugPrint('❌ Database connection failed: ${connectionStatus['error']}');
    }
  } catch (e) {
    debugPrint('❌ Connection test failed: $e');
  }
  
  // Skip notification initialization on web (requires service worker setup)
  // TODO: Implement push notification initialization
  // if (!kIsWeb) {
  //   await NotificationService.initialize();
  // }
  
  runApp(ProviderScope(
    child: provider.ChangeNotifierProvider<LanguageService>.value(
      value: languageService,
      child: const FieldFreshApp(),
    ),
  ));
}

class FieldFreshApp extends ConsumerWidget {
  const FieldFreshApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (context) => AuthService()),
        provider.Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return MaterialApp.router(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              
              // Localization configuration
              locale: languageService.currentLocale,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LanguageService.supportedLocales,
              
              // Router configuration
              routerConfig: createAppRouter(
                provider.Provider.of<AuthService>(context, listen: false),
                languageService,
              ),
            );
          },
        ),
      ],
    );
  }
}
