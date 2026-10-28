import 'package:flutter/material.dart';

import 'camera_screen.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _classes = [
    'Dakshinamurthy',
    'Dancing Shiva',
    'Durga',
    'Nandi',
    'Shiva–Parvati',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.terracotta, AppColors.brown],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.temple_hindu_outlined,
                            size: 96,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Kailasanathar\nHeritage Explorer',
                        style: TextStyle(
                          fontFamily: kSerif,
                          fontSize: 32,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brown,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Identify sculptures from the Kailasanathar Temple, '
                        'Kanchipuram — fully offline.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppColors.brown.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final n in _classes)
                            Chip(
                              label: Text(n),
                              backgroundColor: AppColors.gold.withValues(
                                alpha: 0.18,
                              ),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: AppColors.brown,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Identify'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('Explore'),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                              const SnackBar(
                                content: Text('Explore: coming next'),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
