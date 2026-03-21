import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';
import '../core/constants.dart';

class NavigationGuard {
  static final AuthService _authService = AuthService();

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const publicRoutes = [
      AppRoutes.roleSelect,
      AppRoutes.login,
      AppRoutes.customerLogin,
      AppRoutes.farmerLogin,
      AppRoutes.adminLogin,
      AppRoutes.otp,
      AppRoutes.otpVerify,
      AppRoutes.signup,
      '/verification-flow',
    ];
    
    return !publicRoutes.contains(route);
  }

  /// Check if user has permission to access route
  static bool hasPermission(String route, String? userRole) {
    // Admin routes
    if (route.startsWith('/admin')) {
      return userRole == 'admin';
    }
    
    // Farmer routes
    if (route.startsWith('/farmer')) {
      return userRole == 'farmer';
    }
    
    // Customer routes
    if (route.startsWith('/customer')) {
      return userRole == 'customer';
    }
    
    // Public routes
    return true;
  }

  /// Get redirect route for unauthorized access
  static String getRedirectRoute(String attemptedRoute) {
    if (!_authService.isAuthenticated) {
      // Not logged in - redirect to role selection
      return AppRoutes.roleSelect;
    }
    
    // Logged in but wrong role - redirect to appropriate home
    return _authService.getHomeRoute();
  }

  /// Handle navigation guard logic
  static Future<String?> handleNavigation(BuildContext context, GoRouterState state) async {
    final route = state.fullPath ?? state.path ?? '/';
    final isAuthenticated = _authService.isAuthenticated;
    final userRole = _authService.currentUserRole;

    print('NavigationGuard: Checking route: $route');
    print('NavigationGuard: Authenticated: $isAuthenticated, Role: $userRole');

    // Allow access to public routes
    if (!requiresAuth(route)) {
      // If user is already authenticated and tries to access login/role select,
      // check if they need verification first
      if (isAuthenticated && (route == AppRoutes.roleSelect || route.contains('/login'))) {
        final postLoginRoute = await _authService.getPostLoginRoute();
        print('NavigationGuard: Redirecting authenticated user to: $postLoginRoute');
        return postLoginRoute;
      }
      return null; // Allow access
    }

    // Check authentication for protected routes
    if (!isAuthenticated) {
      print('NavigationGuard: User not authenticated, redirecting to role select');
      return AppRoutes.roleSelect;
    }

    // Check if user needs verification before accessing protected routes
    if (route != '/verification-flow') {
      final needsVerification = await _authService.needsVerification();
      if (needsVerification) {
        print('NavigationGuard: User needs verification, redirecting to verification flow');
        return '/verification-flow';
      }
    }

    // Check role permissions
    if (!hasPermission(route, userRole)) {
      final homeRoute = _authService.getHomeRoute();
      print('NavigationGuard: User lacks permission, redirecting to home: $homeRoute');
      return homeRoute;
    }

    // Allow access
    return null;
  }

  /// Secure logout with navigation handling
  static Future<void> secureLogout(BuildContext context) async {
    try {
      // Perform logout
      await _authService.logout(context: context);
      
      // Ensure we're on the role select screen
      if (context.mounted) {
        context.go(AppRoutes.roleSelect);
      }
    } catch (e) {
      print('Secure logout error: $e');
      // Force navigation to role select even if logout fails
      if (context.mounted) {
        context.go(AppRoutes.roleSelect);
      }
    }
  }

  /// Clear navigation history and go to route
  static void clearHistoryAndNavigate(BuildContext context, String route) {
    if (context.mounted) {
      context.go(route);
    }
  }
}