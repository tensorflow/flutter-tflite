import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class NerClassifier {
  late Interpreter _interprete;
  late Map<String, int> _word2idx;
  late Map<int, String> _id2tag;
  late int _maxLen;
  late int _numTags;

  NerClassifier() {
    init();
  }

  /// Call this before using [predict]
  Future<void> init() async {
    // 1. Load the TFLite model from assets
    try {
      var opt = InterpreterOptions()..addDelegate(Flex_Delegate());

      _interprete = await Interpreter.fromAsset('assets/model/ner_model.tflite',
          options: opt);
      print('Nermodel loaded successfully');
    } catch (e) {
      print('Error loading Nermodel: $e');
    }

    // 2. Load vocab and tag mappings
    final wordJson = await rootBundle.loadString('assets/model/word2idx.json');
    final tagJson = await rootBundle.loadString('assets/model/tag2idx.json');

    _word2idx = (jsonDecode(wordJson) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
    final tag2idx = (jsonDecode(tagJson) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
    _id2tag = {for (var e in tag2idx.entries) e.value: e.key};

    // 3. Read model input/output shapes
    final inputDetail = _interprete.getInputTensor(0);
    final outputDetail = _interprete.getOutputTensor(0);
    _maxLen = inputDetail.shape[1];
    _numTags = outputDetail.shape[2];

    // List<Map<String, String>> data = predict();

    // print("mdmdmdmdmmdmd $data");
  }

  /// Preprocess a sentence into the model’s expected [List<List<double>>].
  List<List<double>> _preprocess(String sentence) {
    final tokens = sentence.trim().split(RegExp(r'\s+'));
    // Map tokens to indices, using OOV=1 and PAD=0
    final seq = List<int>.generate(
      _maxLen,
      (i) => i < tokens.length
          ? _word2idx[tokens[i]] ?? _word2idx['OOVword']!
          : _word2idx['PADword']!,
    );
    // Convert to List<List<double>> for interpreter.run
    return [seq.map((e) => e.toDouble()).toList()];
  }

  /// Runs inference and returns [(token, predictedTag)] pairs.
  List<Map<String, String>> predict(String sentence) {
    // 1. Preprocess
    final tokens = sentence.trim().split(RegExp(r'\s+'));
    final input = _preprocess(sentence);

    // 2. Prepare output buffer: shape [1, _maxLen, _numTags]
    final output = List.generate(
      1,
      (_) => List.generate(
        _maxLen,
        (_) => List.filled(_numTags, 0.0),
      ),
    );

    // 3. Run the model
    _interprete.run(input, output);

    // 4. Post-process: for each token, pick highest-probability tag
    final results = <Map<String, String>>[];
    for (var i = 0; i < tokens.length && i < _maxLen; i++) {
      final scores = output[0][i];
      var maxIdx = 0;
      for (var j = 1; j < scores.length; j++) {
        if (scores[j] > scores[maxIdx]) maxIdx = j;
      }
      results.add({tokens[i]: _id2tag[maxIdx]!});
    }
    return results;
  }

  /// Release native resources
  void close() {
    _interprete.close();
  }
}
