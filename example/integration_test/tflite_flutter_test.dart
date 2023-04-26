// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 1))

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

final dataFileName = 'permute_uint8.tflite';
final missingFileName = 'missing.tflite';
final badFileName = 'bad_model.tflite';
final quantFileName = 'mobilenet_quant.tflite';
final intFileName = 'int32.bin';
final int64FileName = 'int64.bin';
final multiInputFileName = 'multi_add.bin';
final addFileName = 'add.bin';

//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/tflite_flutter_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('version', () {
    expect(tfl.version, isNotEmpty);
    print('TensorFlow Lite version: ${tfl.version}');
  });

  test('interpreter from file', () async {
    final dataFile = await getFile(dataFileName);
    var interpreter = tfl.Interpreter.fromFile(dataFile);
    interpreter.close();
  });

  test('interpreter from buffer', () async {
    final buffer = await getBuffer(dataFileName);
    var interpreter = tfl.Interpreter.fromBuffer(buffer);
    interpreter.close();
  });

  test('interpreter from asset', () async {
    final interpreter = await tfl.Interpreter.fromAsset('test/$dataFileName');
    interpreter.close();
  });

  test('interpreter from address', () async {
    final interpreter = await tfl.Interpreter.fromAsset('test/$dataFileName');
    final interpreter2 = tfl.Interpreter.fromAddress(interpreter.address);
    interpreter2.close();
  });

  group('interpreter options', () {
    test('default', () async {
      final dataFile = await getFile(dataFileName);

      var options = tfl.InterpreterOptions();
      var interpreter = tfl.Interpreter.fromFile(dataFile, options: options);
      options.delete();
      interpreter.allocateTensors();
      interpreter.invoke();
      interpreter.close();
    });

    test('threads', () async {
      final dataFile = await getFile(dataFileName);

      var options = tfl.InterpreterOptions()..threads = 1;
      var interpreter = tfl.Interpreter.fromFile(dataFile, options: options);
      options.delete();
      interpreter.allocateTensors();
      interpreter.invoke();
      interpreter.close();
    });
  });

  group('interpreter', () {
    late tfl.Interpreter interpreter;
    setUp(() async {
      final dataFile = await getFile(dataFileName);
      interpreter = tfl.Interpreter.fromFile(dataFile);
    });
    tearDown(() => interpreter.close());

    test('allocate', () {
      interpreter.allocateTensors();
    });

    test('invoke throws if not allocated after resized', () {
      interpreter.allocateTensors();
      interpreter.resizeInputTensor(0, [1, 2, 4]);
      expect(() => interpreter.invoke(), throwsA(isStateError));
    });

    test('invoke succeeds if allocated', () {
      interpreter.allocateTensors();
      interpreter.invoke();
    });

    test('get input tensors', () {
      expect(interpreter.getInputTensors(), hasLength(1));
    });

    test('get input tensor', () {
      expect(interpreter.getInputTensor(0), isNotNull);
    });

    test('get input tensor throws argument error', () {
      expect(() => interpreter.getInputTensor(33), throwsA(isArgumentError));
    });

    test('get input tensor index', () {
      var name = interpreter.getInputTensors()[0].name;
      expect(interpreter.getInputIndex(name), 0);
    });

    test('get input tensor index throws argument error', () {
      expect(() => interpreter.getInputIndex('abcd'), throwsA(isArgumentError));
    });

    test('get output tensors', () {
      expect(interpreter.getOutputTensors(), hasLength(1));
    });

    test('get output tensor', () {
      expect(interpreter.getOutputTensor(0), isNotNull);
    });

    test('get output tensor throws argument error', () {
      expect(() => interpreter.getOutputTensor(33), throwsA(isArgumentError));
    });

    test('get output tensor index', () {
      var name = interpreter.getOutputTensors()[0].name;
      expect(interpreter.getOutputIndex(name), 0);
    });

    test('get output tensor index throws argument error', () {
      expect(
          () => interpreter.getOutputIndex('abcd'), throwsA(isArgumentError));
    });

    test('resize input tensor', () {
      interpreter.resizeInputTensor(0, [2, 3, 5]);
      expect(interpreter.getInputTensors().single.shape, [2, 3, 5]);
    });

    group('tensors', () {
      late List<tfl.Tensor> tensors;
      setUp(() => tensors = interpreter.getInputTensors());

      test('name', () {
        expect(tensors[0].name, 'input');
      });

      test('type', () {
        expect(tensors[0].type, tfl.TfLiteType.uint8);
      });

      test('shape', () {
        expect(tensors[0].shape, [1, 4]);
      });

      group('data', () {
        test('get', () {
          interpreter.allocateTensors();
          expect(tensors[0].data, hasLength(4));
        });

        test('set', () {
          interpreter.allocateTensors();
          tensors[0].data = Uint8List.fromList(const [0, 0, 0, 0]);
          expect(tensors[0].data, [0, 0, 0, 0]);
          tensors[0].data = Uint8List.fromList(const [0, 1, 10, 100]);
          expect(tensors[0].data, [0, 1, 10, 100]);
        });
      });

      if (Platform.isAndroid) {
        group('quantization', () {
          late tfl.Interpreter interpreter;
          setUp(() async {
            interpreter =
                await tfl.Interpreter.fromAsset('test/$quantFileName');
          });
          test('params', () {
            interpreter.allocateTensors();
            final tensor = interpreter.getInputTensor(0);
            print(tensor.params);
          });
          tearDown(() => interpreter.close());
        });
      }
    });
  });

  group('inference', () {
    group('with float32', () {
      test('single input', () async {
        tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset('test/$addFileName');
        var four =
            List.filled(1, List.filled(8, List.filled(8, [1.23, 6.54, 7.81])));
        var output = List.filled(1 * 8 * 8 * 3, 0.0).reshape([1, 8, 8, 3]);
        interpreter.run(four, output);
        var exp = '';
        if (output[0][0][0][0] is double) {
          exp = (output[0][0][0][0] as double).toStringAsFixed(2);
        }
        expect(exp, '3.69');
        interpreter.close();
      });

      test('single input bytes', () async {
        tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset('test/$addFileName');
        var four =
            List.filled(1, List.filled(8, List.filled(8, [1.23, 6.54, 7.81])));
        var output = List.filled(1 * 8 * 8 * 3, 0.0).reshape([1, 8, 8, 3]);
        var inputBytes = tfl.ByteConversionUtils.convertObjectToBytes(
            four, tfl.TfLiteType.float32);
        var outputBytes = tfl.ByteConversionUtils.convertObjectToBytes(
            output, tfl.TfLiteType.float32);
        interpreter.run(inputBytes, outputBytes);
        var outputList = tfl.ByteConversionUtils.convertBytesToObject(
                outputBytes, tfl.TfLiteType.float32, [1, 8, 8, 3])
            as List<List<List<List<double>>>>;
        expect(outputList[0][0][0][0].toStringAsFixed(2), '3.69');
        interpreter.close();
      });

      test('single input buffer', () async {
        tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset('test/$addFileName');
        var four =
            List.filled(1, List.filled(8, List.filled(8, [1.23, 6.54, 7.81])));
        var output = List.filled(1 * 8 * 8 * 3, 0.0).reshape([1, 8, 8, 3]);
        var inputBuffer = tfl.ByteConversionUtils.convertObjectToBytes(
                four, tfl.TfLiteType.float32)
            .buffer;
        var outputBuffer = tfl.ByteConversionUtils.convertObjectToBytes(
                output, tfl.TfLiteType.float32)
            .buffer;
        interpreter.run(inputBuffer, outputBuffer);
        var outputElement =
            ByteData.view(outputBuffer).getFloat32(0, Endian.little);
        expect(outputElement.toStringAsFixed(2), '3.69');
        interpreter.close();
      });

      test('multiple input', () async {
        late tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset(
          'test/$multiInputFileName',
        );
        final inputTensors = interpreter.getInputTensors();
        expect(inputTensors.length, 4);
        expect(inputTensors[0].type, tfl.TfLiteType.float32);
        expect(inputTensors[1].type, tfl.TfLiteType.float32);
        expect(inputTensors[2].type, tfl.TfLiteType.float32);
        expect(inputTensors[3].type, tfl.TfLiteType.float32);

        final outputTensors = interpreter.getOutputTensors();
        expect(outputTensors.length, 2);
        expect(outputTensors[0].type, tfl.TfLiteType.float32);
        expect(outputTensors[1].type, tfl.TfLiteType.float32);

        var input0 = [1.23];
        var input1 = [2.43];
        var inputs = [input0, input1, input0, input1];
        var output0 = List<double>.filled(1, 0);
        var output1 = List<double>.filled(1, 0);
        var outputs = {0: output0, 1: output1};
        interpreter.runForMultipleInputs(inputs, outputs);
        print(interpreter.lastNativeInferenceDurationMicroSeconds);
        expect(output0[0].toStringAsFixed(2), '4.89');
        expect(output1[0].toStringAsFixed(2), '6.09');
        interpreter.close();
      });
      test('multiple input multiple threads', () async {
        tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset(
            'test/$multiInputFileName',
            options: tfl.InterpreterOptions()..threads = 2);
        final inputTensors = interpreter.getInputTensors();
        expect(inputTensors.length, 4);
        expect(inputTensors[0].type, tfl.TfLiteType.float32);
        expect(inputTensors[1].type, tfl.TfLiteType.float32);
        expect(inputTensors[2].type, tfl.TfLiteType.float32);
        expect(inputTensors[3].type, tfl.TfLiteType.float32);

        final outputTensors = interpreter.getOutputTensors();
        expect(outputTensors.length, 2);
        expect(outputTensors[0].type, tfl.TfLiteType.float32);
        expect(outputTensors[1].type, tfl.TfLiteType.float32);

        var input0 = [1.23];
        var input1 = [2.43];
        var inputs = [input0, input1, input0, input1];
        var output0 = List<double>.filled(1, 0);
        var output1 = List<double>.filled(1, 0);
        var outputs = {0: output0, 1: output1};
        interpreter.runForMultipleInputs(inputs, outputs);
        print(interpreter.lastNativeInferenceDurationMicroSeconds);
        expect(output0[0].toStringAsFixed(2), '4.89');
        expect(output1[0].toStringAsFixed(2), '6.09');
        interpreter.close();
      });
    });
    test('with int32', () async {
      tfl.Interpreter interpreter;
      final path = await getPathOnDevice(intFileName);
      interpreter = tfl.Interpreter.fromFile(File(path));
      final oneD = <int>[3, 7, -4];
      final twoD = List.filled(8, oneD);
      final threeD = List.filled(8, twoD);
      final fourD = List.filled(2, threeD);

      var output = List.filled(2 * 4 * 4 * 12, 0).reshape([2, 4, 4, 12]);

      interpreter.run(fourD, output);

      expect(output[0][0][0], [3, 7, -4, 3, 7, -4, 3, 7, -4, 3, 7, -4]);
      interpreter.close();
    });
    test('with int64', () async {
      tfl.Interpreter interpreter;
      final path = await getPathOnDevice(int64FileName);
      interpreter = tfl.Interpreter.fromFile(File(path));
      print(interpreter.getInputTensor(0));
      final oneD = <int>[3, 7, -4];
      final twoD = List.filled(8, oneD);
      final threeD = List.filled(8, twoD);
      final fourD = List.filled(2, threeD);

      var output = List.filled(2 * 4 * 4 * 12, 0).reshape([2, 4, 4, 12]);

      interpreter.run(fourD, output);

      expect(output[0][0][0], [3, 7, -4, 3, 7, -4, 3, 7, -4, 3, 7, -4]);
      interpreter.close();
    });

    if (Platform.isAndroid) {
      test('using set use NnApi', () async {
        tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset('test/$addFileName',
            options: tfl.InterpreterOptions()..useNnApiForAndroid = true);
        var o = [1.23, 6.54, 7.81];
        var two = [o, o, o, o, o, o, o, o];
        var three = [two, two, two, two, two, two, two, two];
        var four = [three];
        var output = List.filled(1 * 8 * 8 * 3, 0).reshape([1, 8, 8, 3]);
        interpreter.run(four, output);
        var exp = '';
        if (output[0][0][0][0] is double) {
          exp = (output[0][0][0][0] as double).toStringAsFixed(2);
        }
        expect(exp, '3.69');
        interpreter.close();
      });
      test('using NnApiDelegate', () async {
        tfl.Interpreter interpreter;
        interpreter = await tfl.Interpreter.fromAsset(
          'test/$addFileName',
          options: tfl.InterpreterOptions()..useNnApiForAndroid = true,
        );
        var o = [1.23, 6.54, 7.81];
        var two = [o, o, o, o, o, o, o, o];
        var three = [two, two, two, two, two, two, two, two];
        var four = [three];
        var output = List.filled(1 * 8 * 8 * 3, 0).reshape([1, 8, 8, 3]);
        interpreter.run(four, output);
        var exp = '';
        if (output[0][0][0][0] is double) {
          exp = (output[0][0][0][0] as double).toStringAsFixed(2);
        }
        expect(exp, '3.69');
        interpreter.close();
      });

      // Unable to create interpreter
      test('using GpuDelegateV2 android', () async {
        tfl.Interpreter interpreter;
        final gpuDelegate = tfl.GpuDelegateV2();
        var interpreterOptions = tfl.InterpreterOptions()
          ..addDelegate(gpuDelegate);
        interpreter = await tfl.Interpreter.fromAsset(
            'text_classification.tflite',
            options: interpreterOptions);
        expect(interpreter, isNotNull);
        interpreter.close();
      });

      if (Platform.isIOS) {
        test('using GpuDelegate iOS', () async {
          tfl.Interpreter interpreter;
          final gpuDelegate = tfl.GpuDelegate();
          var interpreterOptions = tfl.InterpreterOptions()
            ..addDelegate(gpuDelegate);
          interpreter = await tfl.Interpreter.fromAsset('test/$addFileName',
              options: interpreterOptions);
          var o = [1.23, 6.54, 7.81];
          var two = [o, o, o, o, o, o, o, o];
          var three = [two, two, two, two, two, two, two, two];
          var four = [three];
          var output = List.filled(1 * 8 * 8 * 3, 0).reshape([1, 8, 8, 3]);
          interpreter.run(four, output);
          var exp = '';
          if (output[0][0][0][0] is double) {
            exp = (output[0][0][0][0] as double).toStringAsFixed(2);
          }
          expect(exp, '3.69');
          interpreter.close();
        });
      }
    }
  });

  group('tensor static', () {
    test('dataTypeOf', () {
      var d = 2.0;
      var dList = [
        [
          [2.0],
          [2.0]
        ]
      ];
      var i = 1;
      var str = 'str';
      expect(tfl.Tensor.dataTypeOf(d), tfl.TfLiteType.float32);
      expect(tfl.Tensor.dataTypeOf(dList), tfl.TfLiteType.float32);
      expect(tfl.Tensor.dataTypeOf(i), tfl.TfLiteType.int32);
      expect(tfl.Tensor.dataTypeOf(str), tfl.TfLiteType.string);
    });

    test('dataTypeOf throws Argument error', () {
      expect(() => tfl.Tensor.dataTypeOf({0: 'a'}), throwsA(isArgumentError));
    });
  });

  group('extension Reshaping', () {
    test('shape', () {
      var list1D = [0.0, 2.0, 1.0, 3.0];
      var list2D = [
        [1, 2, 3],
        [1, 2, 3]
      ];
      var list3D = [
        [
          [1, 2],
          [1, 2]
        ],
        [
          [1, 2],
          [1, 2]
        ]
      ];
      expect(list1D.shape, [4]);
      expect(list2D.shape, [2, 3]);
      expect(list3D.shape, [2, 2, 2]);
    });

    test('reshape', () {
      var list = <double>[0.0, 1.0, 2.0, 3.0];
      var listReshaped = list.reshape([2, 2]);
      expect(listReshaped, [
        [0.0, 1.0],
        [2.0, 3.0]
      ]);
    });
  });

  if (Platform.isAndroid) {
    group('gpu delegate android', () {
      final gpuDelegate = tfl.GpuDelegateV2();
      test('create', () {
        expect(gpuDelegate, isNotNull);
      });
      test('delete', gpuDelegate.delete);
    });
  }
  if (Platform.isIOS) {
    group('gpu delegate ios', () {
      final gpuDelegate = tfl.GpuDelegate(
        options: tfl.GpuDelegateOptions(),
      );
      test('create', () {
        expect(gpuDelegate, isNotNull);
      });
      test('delete', gpuDelegate.delete);
    });
  }
}

Future<File> getFile(String fileName) async {
  final appDir = await getTemporaryDirectory();
  final appPath = appDir.path;
  final fileOnDevice = File('$appPath/$fileName');
  final rawAssetFile = await rootBundle.load('assets/test/$fileName');
  final rawBytes = rawAssetFile.buffer.asUint8List();
  await fileOnDevice.writeAsBytes(rawBytes, flush: true);
  return fileOnDevice;
}

Future<String> getPathOnDevice(String assetFileName) async {
  final fileOnDevice = await getFile(assetFileName);
  return fileOnDevice.path;
}

Future<Uint8List> getBuffer(String assetFileName) async {
  final rawAssetFile = await rootBundle.load('assets/test/$assetFileName');
  final rawBytes = rawAssetFile.buffer.asUint8List();
  return rawBytes;
}
