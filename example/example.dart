import 'package:flutter/widgets.dart';
import 'package:tflite_core/tflite_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add a float32 model with input shape [1, 5] and output shape [1, 2]
  // to assets/model.tflite and declare it in the Flutter app's pubspec.yaml.
  final interpreter = await Interpreter.fromAsset('assets/model.tflite');
  try {
    final input = [
      [1.23, 6.54, 7.81, 3.21, 2.22]
    ];
    final output = List<double>.filled(2, 0).reshape<double>([1, 2]);

    interpreter.run(input, output);
    debugPrint(output.toString());
  } finally {
    interpreter.close();
  }
}
