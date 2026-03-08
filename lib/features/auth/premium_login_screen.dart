import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';

class PremiumLoginScreen extends StatefulWidget {
  final String role;
  const PremiumLoginScreen({super.key, required this.role});
  @override
  State<PremiumLoginScreen> createState() => _PremiumLoginScreenState();
}

class _PremiumLoginScreenState extends State<PremiumLoginScreen>
    with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _roleData = {
    'farmer': {
      'emoji': '👨‍🌾',
      'title': 'Farmer Login',
      'subtitle': 'Sell your harvest, grow your business',
      'gradient': LinearGradient(
        colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    'customer': {
      'emoji': '🛒',
      'title': 'Customer Login',
      'subtitle': 'Fresh from farm to your table',
      'gradient': LinearGradient(
        colors: [Color(0xFF1B6CA8), Color(0xFF145080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    'admin': {
      'emoji': '🔐',
      'title': 'Admin Login',
      'subtitle': 'Manage the entire platform',
      'gradient': LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final phone = '+91${_phoneCtrl.text.trim()}';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Checking your account...'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final existingUser = await SupabaseService.getUserByPhone(phone);

      if (existingUser != null) {
        final userRole = existingUser['role'] as String;
        final isKycDone = existingUser['is_kyc_done'] as bool? ?? false;

        if (!isKycDone) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📝 Welcome back! Please complete your profile'),
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(AppRoutes.kycSetup, extra: {
              'role': userRole,
              'userId': existingUser['id'],
              'phone': phone,
            });
          }
        } else {
          SupabaseService.setDemoUserId(existingUser['id'] as String);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Welcome back, ${existingUser['name']}!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );

            if (userRole == 'farmer') {
              context.go(AppRoutes.farmerHome);
            } else if (userRole == 'customer') {
              context.go(AppRoutes.customerHome);
            } else if (userRole == 'admin') {
              context.go(AppRoutes.adminDashboard);
            } else {
              context.go(AppRoutes.customerHome);
            }
          }
        }
      } else {
        if (mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Text('🎉 '),
                  Expanded(
                    child: Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This number is not registered yet.\n\nWould you like to create a new account?',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Yes, Sign Up'),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📝 Creating your account...'),
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );

            final newUserId =
                await SupabaseService.createBasicUser(phone, widget.role);

            context.go(AppRoutes.kycSetup, extra: {
              'role': widget.role,
              'userId': newUserId,
              'phone': phone,
            });
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        String errorMessage = 'Connection error. Please check:\n'
            '1. Internet connection\n'
            '2. Supabase project is active\n'
            '3. Try again in a moment';

        if (e.toString().contains('Failed to fetch')) {
          errorMessage = '⚠️ Cannot connect to server.\n\n'
              'Please check your internet connection and try again.';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Connection Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _roleData[widget.role] ?? _roleData['customer']!;
    final gradient = data['gradient'] as LinearGradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.go(AppRoutes.roleSelect),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Secure Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Role Icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                data['emoji'] as String,
                                style: const TextStyle(fontSize: 64),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          Text(
                            data['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            data['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Login Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Enter your mobile number',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'We\'ll send you an OTP to verify',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Phone Input
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Mobile Number',
                                      hintText: '9876543210',
                                      prefixIcon: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '🇮🇳',
                                              style: TextStyle(fontSize: 24),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '+91',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.dark,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 1,
                                              height: 24,
                                              color: AppColors.textHint,
                                            ),
                                          ],
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: AppColors.error,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => (v?.length ?? 0) != 10
                                        ? 'Enter a valid 10-digit number'
                                        : null,
                                  ),
                                  const SizedBox(height: 24),

                                  // Send OTP Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _sendOtp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: gradient.colors.first,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Send OTP',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Terms
                                  Text(
                                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Info Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Existing user? Login directly\nNew user? We\'ll create your account',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
