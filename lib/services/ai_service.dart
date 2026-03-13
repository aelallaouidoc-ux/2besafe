import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class PredictionResult {
  final int predictedClass;
  final double probBaseline;
  final double probStress;
  final String riskLabel;

  PredictionResult({
    required this.predictedClass,
    required this.probBaseline,
    required this.probStress,
    required this.riskLabel,
  });
}

class AiService {
  OrtSession? _session;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    OrtEnv.instance.init();

    const modelPath = 'assets/models/random_forest_wesad.onnx';
    final rawAssetFile = await rootBundle.load(modelPath);
    final bytes = rawAssetFile.buffer.asUint8List();

    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);

    _isInitialized = true;
  }

  Future<PredictionResult> predict(List<double> features) async {
    if (!_isInitialized || _session == null) {
      throw Exception('AI model is not initialized.');
    }

    final inputName = _session!.inputNames.first;

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(features),
      [1, features.length],
    );

    final runOptions = OrtRunOptions();

    final outputs = await _session!.runAsync(
      runOptions,
      {inputName: inputTensor},
    );

    inputTensor.release();
    runOptions.release();

    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      throw Exception('Model returned no output.');
    }

    final outputValue = outputs.first!.value;

    for (final out in outputs) {
      out?.release();
    }

    // Selon le modèle ONNX exporté, la sortie peut être différente.
    // On gère ici le cas le plus fréquent : une liste de probabilités.
    double probBaseline = 0.0;
    double probStress = 0.0;
    int predictedClass = 0;

    if (outputValue is List) {
      final flat = _flattenToDoubleList(outputValue);

      if (flat.length >= 2) {
        probBaseline = flat[0];
        probStress = flat[1];
        predictedClass = probStress >= probBaseline ? 1 : 0;
      } else if (flat.length == 1) {
        probStress = flat[0];
        probBaseline = 1.0 - probStress;
        predictedClass = probStress >= 0.5 ? 1 : 0;
      }
    }

    final riskLabel = predictedClass == 1 ? 'Stress' : 'Baseline';

    return PredictionResult(
      predictedClass: predictedClass,
      probBaseline: probBaseline,
      probStress: probStress,
      riskLabel: riskLabel,
    );
  }

  List<double> _flattenToDoubleList(dynamic value) {
    final result = <double>[];

    void extract(dynamic v) {
      if (v is num) {
        result.add(v.toDouble());
      } else if (v is List) {
        for (final item in v) {
          extract(item);
        }
      }
    }

    extract(value);
    return result;
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _isInitialized = false;
  }
}