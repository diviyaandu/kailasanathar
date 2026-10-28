import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'india_outline.dart';
import 'temple.dart';
import 'temple_card.dart';
import 'temple_detail_screen.dart';
import 'theme.dart';

class IndiaMapScreen extends StatefulWidget {
  const IndiaMapScreen({super.key});

  @override
  State<IndiaMapScreen> createState() => _IndiaMapScreenState();
}

class _IndiaMapScreenState extends State<IndiaMapScreen> {
  final _tc = TransformationController();
  late final Future<(IndiaOutline, List<Temple>)> _data = _load();
  String? _selected;

  Future<(IndiaOutline, List<Temple>)> _load() async {
    final r = await Future.wait([IndiaOutline.load(), Temple.loadAll()]);
    return (r[0] as IndiaOutline, r[1] as List<Temple>);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _open(Temple t) async {
    setState(() => _selected = t.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => TempleCard(
        temple: t,
        onExplore: () {
          Navigator.pop(sheet);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TempleDetailScreen(temple: t)),
          );
        },
      ),
    );
    if (mounted) setState(() => _selected = null);
  }

  Widget _marker(Temple t, IndiaOutline o, Size size, double zoom) {
    const hit = 48.0;
    final p = o.project(t.lat, t.lon);
    final sel = t.id == _selected;
    final d = sel ? 30.0 : 22.0;
    return Positioned(
      left: p.dx * size.width - hit / 2,
      top: p.dy * size.height - hit / 2,
      width: hit,
      height: hit,
      child: Transform.scale(
        scale: 1 / zoom, // constant on-screen size at any zoom
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _open(t),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? AppColors.gold : AppColors.terracotta,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.temple_hindu,
                size: sel ? 18 : 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _map(IndiaOutline o, List<Temple> temples) => Stack(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final w = math.min(c.maxWidth, c.maxHeight / o.aspect);
          final size = Size(w, w * o.aspect);
          final ordered = [...temples]
            ..sort(
              (a, b) =>
                  (a.id == _selected ? 1 : 0) - (b.id == _selected ? 1 : 0),
            );
          return InteractiveViewer(
            transformationController: _tc,
            minScale: 1,
            maxScale: 8,
            boundaryMargin: const EdgeInsets.all(120),
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _OutlinePainter(o, _tc)),
                    ),
                    Positioned.fill(
                      child: ValueListenableBuilder<Matrix4>(
                        valueListenable: _tc,
                        builder: (_, m, _) {
                          final z = m.getMaxScaleOnAxis();
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final t in ordered) _marker(t, o, size, z),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 16,
        child: IgnorePointer(
          child: Text(
            'Pinch to zoom · tap a marker',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.brown.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text(
        'India Heritage Map',
        style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w700),
      ),
    ),
    body: FutureBuilder<(IndiaOutline, List<Temple>)>(
      future: _data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Map unavailable:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.terracotta),
          );
        }
        final (outline, temples) = snap.data!;
        return _map(outline, temples);
      },
    ),
  );
}

class _OutlinePainter extends CustomPainter {
  final IndiaOutline o;
  final TransformationController tc;
  Path? _path;
  Size? _size;

  _OutlinePainter(this.o, this.tc) : super(repaint: tc);

  @override
  void paint(Canvas canvas, Size s) {
    if (_path == null || _size != s) {
      final p = Path();
      for (final r in o.rings) {
        if (r.length < 3) continue;
        p.moveTo(r.first.dx * s.width, r.first.dy * s.height);
        for (final q in r.skip(1)) {
          p.lineTo(q.dx * s.width, q.dy * s.height);
        }
        p.close();
      }
      _path = p;
      _size = s;
    }
    final z = tc.value.getMaxScaleOnAxis();
    canvas.drawPath(
      _path!,
      Paint()..color = AppColors.gold.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      _path!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / z
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.terracotta.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _OutlinePainter old) => old.o != o;
}
