import 'package:flutter/material.dart';

import 'temple.dart';
import 'temple_card.dart';
import 'theme.dart';

class TempleDetailScreen extends StatelessWidget {
  final Temple temple;
  const TempleDetailScreen({super.key, required this.temple});

  String _title(String k) =>
      k.isEmpty ? k : k[0].toUpperCase() + k.substring(1).replaceAll('_', ' ');

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

  Widget _chip(String t) => Chip(
    label: Text(t),
    backgroundColor: AppColors.gold.withValues(alpha: 0.18),
    side: BorderSide.none,
    labelStyle: const TextStyle(fontSize: 12, color: AppColors.brown),
  );

  @override
  Widget build(BuildContext context) {
    final t = temple;
    final loc =
        '${t.lat.abs().toStringAsFixed(2)}° ${t.lat >= 0 ? 'N' : 'S'}, '
        '${t.lon.abs().toStringAsFixed(2)}° ${t.lon >= 0 ? 'E' : 'W'}';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: AppColors.terracotta,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(background: TempleImage(t.image)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  t.name,
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (t.state.isNotEmpty) _chip(t.state),
                    if (t.period.isNotEmpty) _chip(t.period),
                  ],
                ),
                if (t.description.isNotEmpty) _section('About', t.description),
                for (final e in t.extras.entries)
                  _section(_title(e.key), e.value),
                _section('Location', loc),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
