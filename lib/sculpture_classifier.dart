import 'dart:convert';

//import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Loads sculpture_classifier.tflite + model_info.json and runs inference.
/// Mirrors the Python export exactly: 224x224, raw RGB 0..255, no normalisation.
class SculptureClassifier {
  late Interpreter _interpreter;
  late List<String> labels;
  late double threshold;
  static const int inputSize = 224;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/sculpture_classifier.tflite',
    );
    final infoStr = await rootBundle.loadString('assets/model_info.json');
    final info = json.decode(infoStr) as Map<String, dynamic>;
    labels = List<String>.from(info['labels']);
    threshold = (info['confidence_threshold'] as num).toDouble();
  }

  /// imageBytes: raw bytes of a JPEG/PNG frame (e.g. from camera plugin).
  /// Returns (label, confidence) or (null, confidence) if below threshold.
  Future<(String?, double)> predict(Uint8List imageBytes) async {
    img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) return (null, 0.0);

    // Direct resize to 224x224 -- no crop, no padding (must match training).
    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
    );

    // Build [1, 224, 224, 3] float32 tensor, raw 0..255 values.
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
        }),
      ),
    );

    final output = List.filled(
      1 * labels.length,
      0.0,
    ).reshape([1, labels.length]);
    _interpreter.run(input, output);

    final probs = (output[0] as List).cast<double>();
    double best = -1;
    int bestIdx = -1;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > best) {
        best = probs[i];
        bestIdx = i;
      }
    }
    if (best < threshold) return (null, best);
    return (labels[bestIdx], best);
  }

  void dispose() => _interpreter.close();
}
