import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    {'emoji': '🌾', 'title': 'Direct from Farm', 'subtitle': 'Buy fresh vegetables, fruits & dairy straight from local farmers. No middlemen, better prices.',
     'bg1': Color(0xFF27AE60), 'bg2': Color(0xFF1E8449)},
    {'emoji': '⚡', 'title': 'Harvest Alerts', 'subtitle': 'Get notified the moment a farmer harvests near you. Order in seconds, get it in hours.',
     'bg1': Color(0xFFF39C12), 'bg2': Color(0xFFD68910)},
    {'emoji': '🌟', 'title': 'Freshness Score', 'subtitle': 'AI-powered freshness scoring. Know exactly how fresh your food is before you buy.',
     'bg1': Color(0xFF1B6CA8), 'bg2': Color(0xFF145080)},
    {'emoji': '👥', 'title': 'Group Buying', 'subtitle': 'Join neighbours to buy together. Unlock up to 20% discount on bulk orders.',
     'bg1': Color(0xFF8E44AD), 'bg2': Color(0xFF6C3483)},
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl, itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final s = _slides[i];
            return Container(
              decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [s['bg1'] as Color, s['bg2'] as Color], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Spacer(),
                Container(width: 140, height: 140,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40)),
                  child: Center(child: Text(s['emoji'] as String, style: const TextStyle(fontSize: 80)))),
                const SizedBox(height: 48),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(children: [
                  Text(s['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  Text(s['subtitle'] as String, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16, height: 1.6), textAlign: TextAlign.center),
                ])),
                const Spacer(flex: 2),
              ])),
            );
          },
        ),
        // Indicators + nav
        Positioned(bottom: 48, left: 0, right: 0,
          child: Column(children: [
            SmoothPageIndicator(controller: _ctrl, count: _slides.length,
              effect: ExpandingDotsEffect(dotHeight: 8, dotWidth: 8, activeDotColor: Colors.white,
                  dotColor: Colors.white.withOpacity(0.35), expansionFactor: 3)),
            const SizedBox(height: 28),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                if (_page > 0)
                  TextButton(onPressed: () => _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: const Text('Back', style: TextStyle(color: Colors.white70, fontSize: 15))),
                const Spacer(),
                if (_page < _slides.length - 1)
                  ElevatedButton(
                    onPressed: () => _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                    child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))
                else
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.roleSelect),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                    child: const Text('Get Started 🌾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              ])),
            TextButton(onPressed: () => context.go(AppRoutes.roleSelect),
              child: Text('Skip', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13))),
          ])),
      ]),
    );
  }
}
