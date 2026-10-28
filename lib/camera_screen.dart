import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'result_screen.dart';
import 'sculpture_classifier.dart';
import 'theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final _classifier = SculptureClassifier();
  bool _classifierLoaded = false;
  Map<String, dynamic> _heritage = {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _classifier.load();
      _classifierLoaded = true;
      final s = await rootBundle.loadString('assets/heritage.json');
      _heritage = json.decode(s) as Map<String, dynamic>;
      final cameras = await availableCameras();
      final c = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (_busy || c == null || !c.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      final (label, conf) = await _classifier.predict(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageBytes: bytes,
            label: label,
            confidence: conf,
            info: label == null
                ? null
                : _heritage[label] as Map<String, dynamic>?,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (_classifierLoaded) _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Camera unavailable:\n$_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }
    final ps = c.value.previewSize!;
    final size = MediaQuery.of(context).size;
    final frame = size.width * 0.78;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ps.height,
                height: ps.width,
                child: CameraPreview(c),
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.15)),
          Center(
            child: SizedBox(
              width: frame,
              height: frame,
              child: CustomPaint(painter: _FramePainter()),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 140,
            child: const Text(
              'Frame the sculpture, then tap',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Center(
              child: GestureDetector(
                onTap: _capture,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _busy ? AppColors.gold : AppColors.ivory,
                    ),
                    child: _busy
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.terracotta,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 36.0;
    final w = s.width, h = s.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, 0)
        ..lineTo(l, 0)
        ..moveTo(w - l, 0)
        ..lineTo(w, 0)
        ..lineTo(w, l)
        ..moveTo(w, h - l)
        ..lineTo(w, h)
        ..lineTo(w - l, h)
        ..moveTo(l, h)
        ..lineTo(0, h)
        ..lineTo(0, h - l),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
