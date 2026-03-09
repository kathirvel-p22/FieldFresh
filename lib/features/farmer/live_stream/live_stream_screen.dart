import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});
  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  bool _isLive = false;
  int _viewers = 0;
  int _likes = 0;
  Timer? _viewerTimer;
  final List<String> _comments = [];
  final _commentSamples = ['🔥 Looks so fresh!', '💚 Ordering now!', '🛒 Price please?', '✅ Quality looks great!', '👍 Amazing tomatoes!'];
  int _commentIndex = 0;
  Timer? _commentTimer;

  void _startStream() {
    setState(() { _isLive = true; _viewers = 12; });
    _viewerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() { _viewers += (DateTime.now().second % 3 == 0 ? 1 : -1).clamp(0, 999); });
    });
    _commentTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
        _comments.insert(0, _commentSamples[_commentIndex % _commentSamples.length]);
        _commentIndex++;
        if (_comments.length > 5) _comments.removeLast();
      });
      }
    });
  }

  void _stopStream() {
    _viewerTimer?.cancel(); _commentTimer?.cancel();
    setState(() { _isLive = false; _viewers = 0; _comments.clear(); });
  }

  @override
  void dispose() { _viewerTimer?.cancel(); _commentTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white,
        title: Row(children: [
          const Text('Harvest Live', style: TextStyle(color: Colors.white)),
          if (_isLive) ...[
            const SizedBox(width: 10),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 6, color: Colors.white),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ])),
            const SizedBox(width: 8),
            Text('👥 $_viewers', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ])),
      body: Stack(children: [
        // Camera view placeholder
        Container(width: double.infinity, height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(colors: _isLive
              ? [const Color(0xFF1a2a1a), const Color(0xFF0d1a0d)]
              : [Colors.black87, Colors.black54], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: _isLive
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.videocam, size: 60, color: Colors.white12),
                  const SizedBox(height: 8),
                  Text('📹 Live from your farm', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📹', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 20),
                  const Text('Ready to go live from your field?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Customers can watch you harvest\nand order in real-time!', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.6)),
                ]),
        ),
        // Comments
        if (_isLive && _comments.isNotEmpty)
          Positioned(left: 12, right: 80, bottom: 130,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _comments
                .map((c) => Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                    child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList())),
        // Likes counter
        if (_isLive)
          Positioned(right: 16, bottom: 160,
            child: GestureDetector(onTap: () => setState(() => _likes++),
              child: Column(children: [
                const Text('❤️', style: TextStyle(fontSize: 28)),
                Text('$_likes', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ]))),
        // Controls
        Positioned(bottom: 40, left: 0, right: 0,
          child: Column(children: [
            if (!_isLive) Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: const Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _StreamTip('🌾', 'Show your crop'),
                    _StreamTip('📦', 'Show quantity'),
                    _StreamTip('💬', 'Talk to buyers'),
                    _StreamTip('🛒', 'Take orders'),
                  ]),
                ])),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isLive ? _stopStream : _startStream,
              child: AnimatedContainer(duration: const Duration(milliseconds: 300),
                width: 80, height: 80,
                decoration: BoxDecoration(color: _isLive ? Colors.red : AppColors.secondary, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: (_isLive ? Colors.red : AppColors.secondary).withOpacity(0.5), blurRadius: 20, spreadRadius: 4)]),
                child: Icon(_isLive ? Icons.stop : Icons.videocam, color: Colors.white, size: 36)),
            ),
            const SizedBox(height: 8),
            Text(_isLive ? 'Tap to Stop' : 'Go Live', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }
}

class _StreamTip extends StatelessWidget {
  final String emoji, label;
  const _StreamTip(this.emoji, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}
