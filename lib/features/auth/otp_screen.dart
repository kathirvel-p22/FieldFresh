import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const OtpScreen({super.key, required this.data});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  int _resend = 30;
  Timer? _timer;

  String get _phone => widget.data['phone'] as String;
  String get _role  => widget.data['role']  as String;

  @override
  void initState() { super.initState(); _startResend(); }

  void _startResend() {
    setState(() => _resend = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resend <= 0) { _timer?.cancel(); return; }
      if (mounted) setState(() => _resend--);
    });
  }

  @override
  void dispose() { _pinCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  Future<void> _verify(String pin) async {
    if (pin.length != 6) return;
    setState(() => _loading = true);
    try {
      final resp = await SupabaseService.verifyOTP(_phone, pin);
      if (resp.user == null) throw Exception('Verification failed');
      // Upsert user with role
      final userId = resp.user!.id;
      final existing = await SupabaseService.getUser(userId);
      if (existing == null) {
        context.go(AppRoutes.kycSetup, extra: _role);
      } else if (!existing.isKycDone) {
        context.go(AppRoutes.kycSetup, extra: _role);
      } else {
        context.go(_role == 'farmer' ? AppRoutes.farmerHome : AppRoutes.customerHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Try again.'), backgroundColor: AppColors.error));
      }
      _pinCtrl.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resend > 0) return;
    try {
      await SupabaseService.signInWithOtp(_phone);
      _startResend();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinTheme = PinTheme(
      width: 52, height: 58,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: AppColors.textPrimary),
      body: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          const Text('Verify your number', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('We sent a 6-digit code to\n${_phone.replaceRange(3, 9, '******')}',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
          const SizedBox(height: 40),
          Pinput(
            controller: _pinCtrl, length: 6, autofocus: true,
            defaultPinTheme: pinTheme,
            focusedPinTheme: pinTheme.copyWith(decoration: pinTheme.decoration!.copyWith(
                border: Border.all(color: AppColors.primary, width: 2))),
            onCompleted: _verify,
          ),
          const SizedBox(height: 28),
          if (_loading) const CircularProgressIndicator()
          else Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Didn't receive it? ", style: TextStyle(color: AppColors.textSecondary)),
            GestureDetector(onTap: _resendOtp,
              child: Text(_resend > 0 ? 'Resend in ${_resend}s' : 'Resend OTP',
                style: TextStyle(color: _resend > 0 ? AppColors.textHint : AppColors.primary, fontWeight: FontWeight.w600))),
          ]),
        ],
      )),
    );
  }
}
