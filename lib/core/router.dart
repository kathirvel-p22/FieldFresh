import 'package:go_router/go_router.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/language_selection_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/kyc_screen.dart';
import '../features/auth/verification_flow_screen.dart';
import '../features/farmer/farmer_home.dart';
import '../features/farmer/live_stream/live_stream_screen.dart';
import '../features/customer/customer_home.dart';
import '../features/customer/feed/product_detail_screen.dart';
import '../features/customer/order/checkout_screen.dart';
import '../features/customer/order/order_tracking_screen.dart';
import '../features/admin/admin_home.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'constants.dart';

// Create router with professional session management and language support
GoRouter createAppRouter(AuthService authService, LanguageService languageService) {
  return GoRouter(
    // CRITICAL: Initial route based on authentication and language status
    initialLocation: _getInitialRoute(authService, languageService),
    refreshListenable: authService,
    
    // Professional redirect logic - handles session-based navigation
    redirect: (context, state) async {
      // Wait for auth service to initialize
      if (!authService.isInitialized) {
        return AppRoutes.splash;
      }
      
      // Check if language has been selected
      final hasLanguageSelected = await languageService.hasLanguageBeenSelected();
      if (!hasLanguageSelected && state.uri.path != AppRoutes.languageSelection) {
        return AppRoutes.languageSelection;
      }
      
      final isAuthenticated = authService.isAuthenticated;
      final currentLocation = state.uri.path;
      
      // 🔐 CORE RULE: Once logged in, user should NEVER see login/role screens
      if (isAuthenticated) {
        // Block access to auth screens when logged in
        if (_isAuthScreen(currentLocation)) {
          return authService.getHomeRoute();
        }
        
        // Allow access to protected screens
        return null;
      } else {
        // Not authenticated - only allow auth screens
        if (_isProtectedScreen(currentLocation)) {
          return AppRoutes.roleSelect;
        }
        
        // Allow access to auth screens
        return null;
      }
    },
    routes: [
      // Splash screen for initialization
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      
      // Language Selection (first time only)
      GoRoute(
        path: AppRoutes.languageSelection,
        builder: (_, __) => const LanguageSelectionScreen(),
      ),
      
      // Onboarding (first time users)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      
      // 🚪 AUTH SCREENS (only accessible when NOT logged in)
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, s) => LoginScreen(role: s.extra as String? ?? 'customer'),
      ),
      GoRoute(
        path: AppRoutes.customerLogin,
        builder: (_, __) => const LoginScreen(role: 'customer'),
      ),
      GoRoute(
        path: AppRoutes.farmerLogin,
        builder: (_, __) => const LoginScreen(role: 'farmer'),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (_, __) => const LoginScreen(role: 'admin'),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (_, s) => OtpScreen(data: s.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: AppRoutes.kycSetup,
        builder: (_, s) => KycScreen(extra: s.extra ?? 'farmer'),
      ),
      
      // Verification Flow (accessible during onboarding)
      GoRoute(
        path: '/verification-flow',
        builder: (_, s) {
          return VerificationFlowScreen(
            userId: authService.currentUserId ?? '',
            userRole: authService.currentUserRole ?? 'customer',
          );
        },
      ),
      
      // 🏠 PROTECTED SCREENS (only accessible when logged in)
      
      // Farmer Dashboard and Features
      GoRoute(
        path: AppRoutes.farmerHome,
        builder: (_, __) => const FarmerHome(),
      ),
      GoRoute(
        path: AppRoutes.farmerLiveStream,
        builder: (_, __) => const LiveStreamScreen(),
      ),
      
      // Customer Dashboard and Features
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (_, __) => const CustomerHome(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (_, s) => ProductDetailScreen(
          productId: s.pathParameters['id']!,
          product: s.extra,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, s) => CheckoutScreen(
          cartItems: s.extra as List<Map<String, dynamic>>,
        ),
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        builder: (_, s) => OrderTrackingScreen(
          orderId: s.pathParameters['id']!,
        ),
      ),
      
      // Admin Dashboard and Features
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminHome(),
      ),
    ],
  );
}

// Helper function to determine initial route
String _getInitialRoute(AuthService authService, LanguageService languageService) {
  if (!authService.isInitialized) {
    return AppRoutes.splash;
  }
  
  if (authService.isAuthenticated) {
    // User is logged in - go directly to their dashboard
    return authService.getHomeRoute();
  } else {
    // User not logged in - check if language has been selected
    return AppRoutes.languageSelection; // Will redirect to role select if language already selected
  }
}

// Helper function to check if current location is an auth screen
bool _isAuthScreen(String location) {
  const authScreens = [
    AppRoutes.roleSelect,
    AppRoutes.login,
    AppRoutes.customerLogin,
    AppRoutes.farmerLogin,
    AppRoutes.adminLogin,
    AppRoutes.otpVerify,
    AppRoutes.kycSetup,
    AppRoutes.onboarding,
    AppRoutes.languageSelection,
  ];
  
  return authScreens.contains(location) || location.startsWith('/login');
}

// Helper function to check if current location is a protected screen
bool _isProtectedScreen(String location) {
  const protectedScreens = [
    AppRoutes.farmerHome,
    AppRoutes.customerHome,
    AppRoutes.adminDashboard,
    AppRoutes.farmerLiveStream,
    AppRoutes.productDetail,
    AppRoutes.checkout,
    AppRoutes.orderTracking,
  ];
  
  return protectedScreens.contains(location) || 
         location.startsWith('/farmer') ||
         location.startsWith('/customer') ||
         location.startsWith('/admin');
}

// Legacy router for backward compatibility (deprecated)
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.roleSelect,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(
        path: AppRoutes.roleSelect,
        builder: (_, __) => const RoleSelectScreen()),
    GoRoute(
        path: AppRoutes.login,
        builder: (_, s) => LoginScreen(role: s.extra as String? ?? 'customer')),
    GoRoute(
        path: AppRoutes.otpVerify,
        builder: (_, s) => OtpScreen(data: s.extra as Map<String, dynamic>)),
    GoRoute(
        path: AppRoutes.kycSetup,
        builder: (_, s) => KycScreen(extra: s.extra ?? 'farmer')),
    GoRoute(path: AppRoutes.farmerHome, builder: (_, __) => const FarmerHome()),
    GoRoute(
        path: AppRoutes.customerHome, builder: (_, __) => const CustomerHome()),
    GoRoute(
        path: AppRoutes.adminDashboard, builder: (_, __) => const AdminHome()),
  ],
);
