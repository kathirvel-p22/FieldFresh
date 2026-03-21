import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../../../generated/l10n.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  int _logoTapCount = 0;
  bool _showSessionDebug = false;

  @override
  void initState() {
    super.initState();
    _checkSessionStatus();
  }

  Future<void> _checkSessionStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      setState(() => _showSessionDebug = true);
    }
  }

  Future<void> _clearSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Clear Session'),
        content: const Text(
            'This will clear your current session and allow you to login fresh. '
            'You can login again with your phone number.\n\n'
            'Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Clearing session...'),
                    ],
                  ),
                ),
              );

              // Clear session
              await authService.clearSession();

              // Close loading dialog
              if (mounted) Navigator.pop(context);

              // Show success and refresh
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('✅ Session cleared! You can now login fresh.'),
                    backgroundColor: AppColors.success,
                  ),
                );
                setState(() => _showSessionDebug = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear Session'),
          ),
        ],
      ),
    );
  }

  void _onLogoTap() {
    setState(() => _logoTapCount++);
    if (_logoTapCount >= 5) {
      _showAdminLogin();
      _logoTapCount = 0;
    }
  }

  void _showAdminLogin() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Admin Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter admin code to continue'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Admin code: "admin123" (you can change this)
              if (codeController.text == 'admin123') {
                Navigator.pop(context);
                context.go(AppRoutes.login, extra: 'admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid admin code')),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Session Debug Info (if stuck)
                if (_showSessionDebug)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning,
                                color: AppColors.warning, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Session Issue Detected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You seem to have a stuck session. Clear it to login fresh.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _clearSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Clear Session & Login Fresh',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),
                GestureDetector(
                  onTap: _onLogoTap,
                  child: const Text('🌾', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context)?.selectRole ?? 'Select Your Role',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context)?.chooseRole ?? 'Choose your role to get started',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _RoleCard(
                  emoji: '👨‍🌾',
                  title: S.of(context)?.farmer ?? 'Farmer',
                  subtitle: S.of(context)?.farmerDescription ?? 'Sell your harvest directly to customers',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                  ),
                  onTap: () => context.go(AppRoutes.login, extra: 'farmer'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  emoji: '🛒',
                  title: S.of(context)?.customer ?? 'Customer',
                  subtitle: S.of(context)?.customerDescription ?? 'Buy fresh produce from local farms',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B6CA8), Color(0xFF145080)],
                  ),
                  onTap: () => context.go(AppRoutes.login, extra: 'customer'),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
