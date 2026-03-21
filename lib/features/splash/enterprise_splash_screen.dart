import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/enterprise_service_manager.dart';
import '../../core/constants.dart';

class EnterpriseSplashScreen extends StatefulWidget {
  const EnterpriseSplashScreen({super.key});

  @override
  State<EnterpriseSplashScreen> createState() => _EnterpriseSplashScreenState();
}

class _EnterpriseSplashScreenState extends State<EnterpriseSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;

  String _currentStep = 'Initializing...';
  double _progress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _logoController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Supabase
      _updateProgress('Connecting to database...', 0.2);
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if Supabase is already initialized
      // SupabaseService is always initialized in main.dart

      // Step 2: Initialize Enterprise Services
      _updateProgress('Loading enterprise services...', 0.4);
      await Future.delayed(const Duration(milliseconds: 500));

      final enterpriseManager = EnterpriseServiceManager();
      await enterpriseManager.initialize();

      // Step 3: Check authentication
      _updateProgress('Checking authentication...', 0.6);
      await Future.delayed(const Duration(milliseconds: 500));

      final sessionService = enterpriseManager.sessionService;
      final isAuthenticated = await sessionService.initialize();

      // Step 4: Load user data if authenticated
      if (isAuthenticated) {
        _updateProgress('Loading user profile...', 0.8);
        await Future.delayed(const Duration(milliseconds: 500));

        final session = sessionService.currentSession;
        if (session != null) {
          // Auto-verify existing user data
          await enterpriseManager.trustService.autoVerifyPhone(session.userId,
              '+91XXXXXXXXXX' // This will be updated with actual phone
              );
        }
      }

      // Step 5: Complete initialization
      _updateProgress('Ready to go!', 1.0);
      await Future.delayed(const Duration(milliseconds: 800));

      // Navigate based on authentication status
      if (mounted) {
        if (isAuthenticated) {
          final session = sessionService.currentSession!;
          switch (session.role) {
            case 'farmer':
              context.go(AppRoutes.farmerHome);
              break;
            case 'customer':
              context.go(AppRoutes.customerHome);
              break;
            case 'admin':
              context.go('/admin/enterprise-dashboard');
              break;
            default:
              context.go('/role-selection');
          }
        } else {
          context.go('/role-selection');
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _updateProgress(String step, double progress) {
    if (mounted) {
      setState(() {
        _currentStep = step;
        _progress = progress;
      });
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo Animation
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // App Name
              const Text(
                'FieldFresh',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),

              const SizedBox(height: 8),

              // Version
              const Text(
                'Enterprise v3.0',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 64),

              // Error State
              if (_hasError) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Initialization Failed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _progress = 0.0;
                            _currentStep = 'Initializing...';
                          });
                          _initializeApp();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Progress Indicator
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        // Progress Bar
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Current Step
                        Text(
                          _currentStep,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Progress Percentage
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],

              const Spacer(),

              // Enterprise Features Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Advanced Security • Trust System • Privacy Controls',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
