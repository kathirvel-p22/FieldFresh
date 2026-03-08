import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) { context.go(AppRoutes.onboarding); return; }
    final userId = session.user.id;
    final data = await Supabase.instance.client.from('users').select('role,is_kyc_done').eq('id', userId).maybeSingle();
    if (data == null || !(data['is_kyc_done'] as bool? ?? false)) {
      context.go(AppRoutes.kycSetup, extra: data?['role'] ?? 'customer');
    } else {
      final role = data['role'] as String? ?? 'customer';
      context.go(role == 'farmer' ? AppRoutes.farmerHome : role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.customerHome);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(scale: _scale,
            child: Container(width: 110, height: 110,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)]),
              child: const Center(child: Text('🌾', style: TextStyle(fontSize: 64))))),
          const SizedBox(height: 24),
          FadeTransition(opacity: _fade, child: Column(children: [
            const Text('FieldFresh', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text('Farm to Your Kitchen', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, letterSpacing: 0.5)),
          ])),
          const SizedBox(height: 60),
          FadeTransition(opacity: _fade,
            child: SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: Colors.white.withOpacity(0.7), strokeWidth: 2))),
        ])),
      ),
    );
  }
}
