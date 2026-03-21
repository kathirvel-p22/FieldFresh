import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';
import '../../../services/connection_test_service.dart';
import '../../../services/auth_service.dart';
import '../../../generated/l10n.dart';

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
  bool _isSignUp = false; // Track if user wants to sign up or sign in

  final _roleData = {
    'farmer': {
      'emoji': '👨‍🌾',
      'titleKey': 'farmer',
      'color': AppColors.secondary,
      'descriptionKey': 'farmerDescription'
    },
    'customer': {
      'emoji': '🛒',
      'titleKey': 'customer',
      'color': AppColors.primary,
      'descriptionKey': 'customerDescription'
    },
    'admin': {
      'emoji': '🔐',
      'titleKey': 'admin',
      'color': AppColors.dark,
      'descriptionKey': 'adminDescription'
    },
  };

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuthentication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final phone = '+91${_phoneCtrl.text.trim()}';

      // Test connection first
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔍 ${S.of(context)?.testingConnection ?? 'Testing connection...'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Test database connection
      final connectionStatus =
          await ConnectionTestService.getConnectionStatus();

      if (!connectionStatus['connected']) {
        throw Exception(
            'Database connection failed: ${connectionStatus['error']}');
      }

      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isSignUp) {
        // SIGN UP FLOW - Send OTP for new users
        await _handleSignUpFlow(phone, authService);
      } else {
        // SIGN IN FLOW - Direct login for existing users
        await _handleSignInFlow(phone, authService);
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
            title: Text(S.of(context)?.connectionError ?? 'Connection Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context)?.ok ?? 'OK'),
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

  Future<void> _handleSignUpFlow(String phone, AuthService authService) async {
    // Check if user already exists
    final existingUser = await SupabaseService.getUserByPhone(phone);

    if (existingUser != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 ${S.of(context)?.numberAlreadyRegistered ?? 'This number is already registered. Please use Sign In instead.'}'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // New user - Send OTP for verification
    await _sendOTPForSignUp(phone);
  }

  Future<void> _handleSignInFlow(String phone, AuthService authService) async {
    // Use the new AuthService complete login method
    final result =
        await authService.completeLogin(phone, widget.role, isNewUser: false);

    if (mounted) {
      if (result.success) {
        if (result.needsKyc) {
          // User needs to complete KYC
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('📝 Welcome back! Please complete your profile setup'),
              duration: Duration(seconds: 3),
            ),
          );

          context.go(AppRoutes.kycSetup, extra: {
            'role': result.role,
            'userId': result.userId,
            'phone': result.phone,
          });
        } else {
          // Login successful - navigate to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Welcome back!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          context.go(result.route!);
        }
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Login failed'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _sendOTPForSignUp(String phone) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Sending OTP...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Send OTP using Supabase
      await SupabaseService.signInWithOtp(phone);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 OTP sent! Please verify to create your account.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to OTP verification screen for signup
        context.go(AppRoutes.otpVerify, extra: {
          'phone': phone,
          'role': widget.role,
          'isSignUp': true,
        });
      }
    } catch (e) {
      // Enhanced error handling for OTP issues
      String errorMessage = 'Failed to send OTP';

      if (e.toString().contains('Invalid phone number')) {
        errorMessage =
            'Invalid phone number format. Please check and try again.';
      } else if (e.toString().contains('Rate limit')) {
        errorMessage =
            'Too many OTP requests. Please wait a few minutes and try again.';
      } else if (e.toString().contains('Phone number not authorized')) {
        errorMessage =
            'Phone number not authorized for OTP. Please contact support.';
      } else if (e.toString().contains('Signup not allowed')) {
        errorMessage =
            'New signups are currently disabled. Please contact support.';
      } else {
        errorMessage = 'OTP service error: ${e.toString()}';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🚫 OTP Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                const Text(
                  'Troubleshooting:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Check your internet connection\n'
                  '• Verify phone number is correct\n'
                  '• Try again in a few minutes\n'
                  '• Contact support if issue persists',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Debug Info: ${e.toString()}',
                    style:
                        const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Try demo mode for testing
                  _showDemoModeOption();
                },
                child: const Text('Try Demo Mode'),
              ),
            ],
          ),
        );
      }

      throw Exception(errorMessage);
    }
  }

  void _showDemoModeOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Demo Mode'),
        content: const Text(
            'Demo mode allows you to test the app without OTP verification. '
            'This is useful for testing when OTP service is not available.\n\n'
            'Continue with demo mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Create demo user directly
              final phone = '+91${_phoneCtrl.text.trim()}';

              try {
                // Create basic user record without OTP verification
                final newUserId =
                    await SupabaseService.createBasicUser(phone, widget.role);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '✅ Demo account created! Complete your profile setup.'),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  // Navigate to KYC setup for new user
                  context.go(AppRoutes.kycSetup, extra: {
                    'role': widget.role,
                    'userId': newUserId,
                    'phone': phone,
                    'isNewUser': true,
                    'isDemoMode': true,
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Demo mode failed: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Continue Demo'),
          ),
        ],
      ),
    );
  }

  String _getRoleTitle(BuildContext context) {
    final s = S.of(context);
    switch (widget.role) {
      case 'farmer':
        return s?.farmer ?? 'Farmer';
      case 'customer':
        return s?.customer ?? 'Customer';
      case 'admin':
        return s?.admin ?? 'Admin';
      default:
        return s?.customer ?? 'Customer';
    }
  }

  String _getRoleDescription(BuildContext context) {
    final s = S.of(context);
    switch (widget.role) {
      case 'farmer':
        return s?.farmerDescription ?? 'Sell your fresh produce directly to customers';
      case 'customer':
        return s?.customerDescription ?? 'Buy fresh produce directly from farmers';
      case 'admin':
        return s?.adminDescription ?? 'Manage the platform and users';
      default:
        return s?.customerDescription ?? 'Buy fresh produce directly from farmers';
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
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.go(AppRoutes.roleSelect),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Role Icon and Title
                      Text(
                        data['emoji'] as String,
                        style: const TextStyle(fontSize: 72),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_getRoleTitle(context)} ${_isSignUp ? S.of(context)?.signUp ?? 'Sign Up' : S.of(context)?.signIn ?? 'Sign In'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRoleDescription(context),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Sign Up / Sign In Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = false),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isSignUp
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    S.of(context)?.signIn ?? 'Sign In',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isSignUp ? color : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = true),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isSignUp
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    S.of(context)?.signUp ?? 'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isSignUp ? color : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSignUp ? Icons.person_add : Icons.login,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isSignUp
                                    ? '${S.of(context)?.newToFieldFresh ?? 'New to FieldFresh?'}\n${S.of(context)?.wellSendOtp ?? 'We\'ll send you an OTP'}'
                                    : '${S.of(context)?.alreadyHaveAccount ?? 'Already have an account?'}\n${S.of(context)?.noOtpNeeded ?? 'No OTP needed'}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phone Input Form
                      Form(
                        key: _formKey,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  labelText: S.of(context)?.mobileNumber ?? 'Mobile Number',
                                  prefixText: '+91  ',
                                  prefixStyle: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                validator: (v) => (v?.length ?? 0) != 10
                                    ? S.of(context)?.enterValid10Digit ?? 'Enter valid 10 digit number'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      _loading ? null : _handleAuthentication,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusM),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isSignUp
                                              ? S.of(context)?.sendOtpSignUp ?? 'Send OTP & Sign Up'
                                              : S.of(context)?.signInInstantly ?? 'Sign In Instantly',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                S.of(context)?.byContinguing ?? 'By continuing, you agree to our Terms & Privacy Policy',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
