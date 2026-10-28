import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final String? label; // null => rejected (below threshold)
  final double confidence;
  final Map<String, dynamic>? info;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.label,
    required this.confidence,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final found = label != null && info != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (found) ..._found() else ..._rejected(),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Try again'),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Text(
    t,
    style: const TextStyle(
      fontFamily: kSerif,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
  );

  Widget _confidence(Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Confidence ${(confidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: confidence.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ),
    ],
  );

  Widget _section(String head, String body) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              head.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.45)),
          ],
        ),
      ),
    ),
  );

  List<Widget> _found() => [
    _title(info!['name'] as String),
    const SizedBox(height: 14),
    _confidence(AppColors.terracotta),
    _section('About', info!['description'] as String),
    _section('Significance', info!['significance'] as String),
    _section('Mythology', info!['mythology'] as String),
  ];

  List<Widget> _rejected() => [
    _title('Sculpture not recognised'),
    const SizedBox(height: 14),
    _confidence(AppColors.gold),
    _section(
      'Tip',
      'This doesn\'t match any of the five supported sculptures '
          '(Dakshinamurthy, Dancing Shiva, Durga, Nandi, Shiva–Parvati). '
          'Fill the frame with one sculpture in good light and try again.',
    ),
  ];
}
