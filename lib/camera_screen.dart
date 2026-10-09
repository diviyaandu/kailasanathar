import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sculpture_classifier.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final _classifier = SculptureClassifier();
  Map<String, dynamic> _heritage = {};
  bool _busy = false;
  Timer? _timer;

  // Smoothing: majority vote over the last N predictions.
  final List<String?> _recent = [];
  static const int _window = 5;
  String? _stableLabel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _classifier.load();
    final heritageStr = await rootBundle.loadString('assets/heritage.json');
    _heritage = json.decode(heritageStr);

    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    setState(() {});

    // Run inference every 700ms rather than on every frame.
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_busy || _controller == null || !_controller!.value.isInitialized) {
      return;
    }
    _busy = true;
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final (label, _) = await _classifier.predict(bytes);
      _recent.add(label);
      if (_recent.length > _window) _recent.removeAt(0);
      setState(() => _stableLabel = _majority(_recent));
    } catch (_) {
      // Ignore a failed frame; next tick retries.
    } finally {
      _busy = false;
    }
  }

  String? _majority(List<String?> items) {
    if (items.isEmpty) return null;
    final counts = <String?, int>{};
    for (final i in items) {
      counts[i] = (counts[i] ?? 0) + 1;
    }
    String? best;
    int bestCount = 0;
    counts.forEach((k, v) {
      if (v > bestCount) {
        best = k;
        bestCount = v;
      }
    });
    // Require a real majority, not just a one-off vote, to accept "unknown".
    return bestCount >= (_window ~/ 2 + 1) ? best : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final info = _stableLabel != null ? _heritage[_stableLabel] : null;
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (info != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        info['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(info['description']),
                      const SizedBox(height: 6),
                      Text(
                        'Significance: ${info['significance']}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
