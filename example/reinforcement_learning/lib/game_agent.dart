import 'package:tflite_flutter/tflite_flutter.dart';

class PolicyGradientAgent {
  final _boardSize = 8;
  final _modelFile = 'assets/models/planestrike.tflite';

  late Interpreter _interpreter;

  PolicyGradientAgent() {
    _loadModel();
  }

  void _loadModel() async {
    // Creating the interpreter
    _interpreter = await Interpreter.fromAsset(_modelFile);
  }

  int predict(List<List<double>> boardState) {
    var input = [boardState];
    var output = List.filled(_boardSize * _boardSize, 0)
        .reshape([1, _boardSize * _boardSize]);

    // Run inference
    _interpreter.run(input, output);

    // Argmax
    double max = output[0][0];
    int maxIdx = 0;
    for (int i = 1; i < _boardSize * _boardSize; i++) {
      if (max < output[0][i]) {
        maxIdx = i;
        max = output[0][i];
      }
    }

    return maxIdx;
  }
}
