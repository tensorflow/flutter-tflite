import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Interpreter creation ───────────────────────────────────────────────────
  // If TensorFlowLiteC.xcframework is not linked by SPM, every test here
  // throws: dlsym(RTLD_DEFAULT): symbol not found for 'TfLiteModelCreate'
  // All 6 tests passing confirms the SPM Package.swift fix is working.

  group('TFLite interpreter', () {
    testWidgets('loads from asset model without crashing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      Interpreter? interpreter;
      Object? error;
      try {
        interpreter = await Interpreter.fromAsset(
          'assets/model/nlu_model.tflite',
        );
      } catch (e) {
        error = e;
      }

      expect(error, isNull, reason: 'Interpreter.fromAsset threw: $error');
      expect(interpreter, isNotNull);
      interpreter?.close();
    });

    testWidgets('input and output tensors are accessible', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final interpreter = await Interpreter.fromAsset(
        'assets/model/nlu_model.tflite',
      );
      expect(interpreter.getInputTensors(), isNotEmpty);
      expect(interpreter.getOutputTensors(), isNotEmpty);
      interpreter.close();
    });

    testWidgets('input tensor has expected shape [1, 16]', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final interpreter = await Interpreter.fromAsset(
        'assets/model/nlu_model.tflite',
      );
      final shape = interpreter.getInputTensor(0).shape;
      expect(shape.length, 2);
      expect(shape[0], 1);
      expect(shape[1], 16);
      interpreter.close();
    });

    testWidgets('output tensor count matches model (2 outputs)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final interpreter = await Interpreter.fromAsset(
        'assets/model/nlu_model.tflite',
      );
      expect(interpreter.getOutputTensors().length, 2);
      interpreter.close();
    });

    testWidgets('runs inference without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final interpreter = await Interpreter.fromAsset(
        'assets/model/nlu_model.tflite',
      );

      const maxLen = 16;
      const numIntents = 11;
      const numEntities = 15;

      final input = [
        List.filled(maxLen, 0)
      ];
      final intentOut = List.filled(numIntents, 0.0).reshape([
        1,
        numIntents
      ]);
      final entityOut = List.filled(maxLen * numEntities, 0.0).reshape([
        1,
        maxLen,
        numEntities
      ]);

      Object? error;
      try {
        interpreter.runForMultipleInputs(
          [
            input
          ],
          {
            0: intentOut,
            1: entityOut
          },
        );
      } catch (e) {
        error = e;
      }

      expect(error, isNull, reason: 'runForMultipleInputs threw: $error');

      final intentProbs = (intentOut[0] as List).cast<double>();
      expect(intentProbs.length, numIntents);
      expect(
        intentProbs.any((v) => v != 0.0),
        isTrue,
        reason: 'Intent output is all zeros — inference may not have run',
      );

      interpreter.close();
    });
  });

  // ── Memory management ──────────────────────────────────────────────────────

  group('Interpreter memory management', () {
    testWidgets('multiple open/close cycles do not crash', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      for (var i = 0; i < 3; i++) {
        final interpreter = await Interpreter.fromAsset(
          'assets/model/nlu_model.tflite',
        );
        interpreter.close();
      }
      expect(true, isTrue);
    });
  });
}
