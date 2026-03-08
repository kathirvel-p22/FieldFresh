import 'package:go_router/go_router.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/kyc_screen.dart';
import '../features/farmer/farmer_home.dart';
import '../features/farmer/live_stream/live_stream_screen.dart';
import '../features/customer/customer_home.dart';
import '../features/customer/feed/product_detail_screen.dart';
import '../features/customer/order/checkout_screen.dart';
import '../features/customer/order/order_tracking_screen.dart';
import '../features/admin/admin_home.dart';
import 'constants.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen()),
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
        path: AppRoutes.farmerLiveStream,
        builder: (_, __) => const LiveStreamScreen()),
    GoRoute(
        path: AppRoutes.customerHome, builder: (_, __) => const CustomerHome()),
    GoRoute(
        path: AppRoutes.productDetail,
        builder: (_, s) => ProductDetailScreen(
            productId: s.pathParameters['id']!, product: s.extra)),
    GoRoute(
        path: AppRoutes.checkout,
        builder: (_, s) =>
            CheckoutScreen(cartItems: s.extra as List<Map<String, dynamic>>)),
    GoRoute(
        path: AppRoutes.orderTracking,
        builder: (_, s) =>
            OrderTrackingScreen(orderId: s.pathParameters['id']!)),
    GoRoute(
        path: AppRoutes.adminDashboard, builder: (_, __) => const AdminHome()),
  ],
);
