import 'package:flutter/material.dart';

import 'temple.dart';
import 'theme.dart';

class TempleImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const TempleImage(this.path, {super.key, this.fit = BoxFit.cover});

  Widget get _placeholder => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.terracotta, AppColors.brown],
      ),
    ),
    child: const Center(
      child: Icon(Icons.temple_hindu_outlined, size: 56, color: AppColors.gold),
    ),
  );

  @override
  Widget build(BuildContext context) => path.isEmpty
      ? _placeholder
      : Image.asset(
          path,
          fit: fit,
          width: double.infinity,
          errorBuilder: (_, _, _) => _placeholder,
        );
}

class TempleCard extends StatelessWidget {
  final Temple temple;
  final VoidCallback onExplore;
  const TempleCard({super.key, required this.temple, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final t = temple;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(aspectRatio: 16 / 9, child: TempleImage(t.image)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          t.state,
                          t.period,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.explore_outlined),
                        label: const Text('Explore Temple'),
                        onPressed: onExplore,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
