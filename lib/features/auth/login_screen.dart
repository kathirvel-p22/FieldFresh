import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  final _roleData = {
    'farmer': {
      'emoji': '👨‍🌾',
      'title': 'Farmer Login',
      'color': AppColors.secondary
    },
    'customer': {
      'emoji': '🛒',
      'title': 'Customer Login',
      'color': AppColors.primary
    },
    'admin': {'emoji': '🔐', 'title': 'Admin Login', 'color': AppColors.dark},
  };

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final phone = '+91${_phoneCtrl.text.trim()}';

      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Checking your account...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Check if user exists in database
      final existingUser = await SupabaseService.getUserByPhone(phone);

      if (existingUser != null) {
        // EXISTING USER - Check if they completed KYC
        final userRole = existingUser['role'] as String;
        final isKycDone = existingUser['is_kyc_done'] as bool? ?? false;

        if (!isKycDone) {
          // User registered but didn't complete KYC
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('📝 Welcome back! Please complete your profile setup'),
                duration: Duration(seconds: 3),
              ),
            );
            // Pass user data to KYC screen
            context.go(AppRoutes.kycSetup, extra: {
              'role': userRole,
              'userId': existingUser['id'],
              'phone': phone,
            });
          }
        } else {
          // User is fully registered - Direct login (demo mode, skip OTP)
          // Set demo user ID for session
          SupabaseService.setDemoUserId(existingUser['id'] as String);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Welcome back, ${existingUser['name']}!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );

            // Navigate to appropriate dashboard
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
        // NEW USER - Create account and go to KYC
        if (mounted) {
          // Show signup confirmation dialog
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🎉 Create New Account'),
              content: Text(
                'Phone: $phone\n\n'
                'This number is not registered yet.\n\n'
                'Would you like to create a new ${widget.role} account?',
                style: const TextStyle(height: 1.6),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, Sign Up'),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '📝 Creating your account... Please complete your profile'),
                duration: Duration(seconds: 3),
              ),
            );

            // Create basic user record
            final newUserId =
                await SupabaseService.createBasicUser(phone, widget.role);

            // Go to KYC setup with user data
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
    final color = data['color'] as Color;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: SafeArea(
            child: Column(children: [
          // Back Button
          Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.go(AppRoutes.roleSelect)))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data['emoji'] as String,
                          style: const TextStyle(fontSize: 72)),
                      const SizedBox(height: 16),
                      Text(data['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Enter your phone number to receive an OTP',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.8)),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 40),
                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Existing user? Login directly\nNew user? We\'ll create your account',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                          key: _formKey,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusL),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 20)
                                ]),
                            padding: const EdgeInsets.all(24),
                            child: Column(children: [
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10)
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  prefixText: '+91  ',
                                  prefixStyle: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                validator: (v) => (v?.length ?? 0) != 10
                                    ? 'Enter a valid 10-digit number'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _sendOtp,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: color,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.radiusM))),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Text('Send OTP',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                  )),
                              const SizedBox(height: 12),
                              Text(
                                  'By continuing you agree to our Terms & Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textHint)),
                              const SizedBox(height: 20),
                              // Sign Up Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('New user? ',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14)),
                                  GestureDetector(
                                    onTap: () {
                                      // Show signup info dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('📝 Sign Up'),
                                          content: const Text(
                                            'To create a new account:\n\n'
                                            '1. Enter your phone number\n'
                                            '2. Click "Send OTP"\n'
                                            '3. Complete your profile setup\n\n'
                                            'New users will be automatically registered!',
                                            style: TextStyle(height: 1.6),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Got it!'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                          )),
                    ],
                  ))),
        ])),
      ),
    );
  }
}
