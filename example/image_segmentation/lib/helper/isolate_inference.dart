/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../image_utils.dart';

class IsolateInference {
  static const String _debugName = "TFLITE_INFERENCE";
  final ReceivePort _receivePort = ReceivePort();
  late Isolate _isolate;
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(entryPoint, _receivePort.sendPort,
        debugName: _debugName);
    _sendPort = await _receivePort.first;
  }

  Future<void> close() async {
    _isolate.kill();
    _receivePort.close();
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final InferenceModel isolateModel in port) {
      image_lib.Image? imageInput =
          ImageUtils.convertCameraImage(isolateModel.cameraImage!);

      // rotate image if android because camera image is landscape
      if (Platform.isAndroid) {
        imageInput = image_lib.copyRotate(imageInput!, angle: 90);
      }

      // resize original image to match model shape.
      imageInput = image_lib.copyResize(
        imageInput!,
        width: isolateModel.inputShape[1],
        height: isolateModel.inputShape[2],
      );

      final imageMatrix = List.generate(
        imageInput.height,
        (y) => List.generate(
          imageInput!.width,
          (x) {
            final pixel = imageInput!.getPixel(x, y);
            // normalize -1 to 1
            return [
              (pixel.r - 127.5) / 127.5,
              (pixel.b - 127.5) / 127.5,
              (pixel.g - 127.5) / 127.5
            ];
          },
        ),
      );

      // Set tensor input [1, 257, 257, 3]
      final input = [imageMatrix];
      // Set tensor output [1, 257, 257, 21]
      final output = [
        List.filled(
            isolateModel.outputShape[1],
            List.filled(isolateModel.outputShape[2],
                List.filled(isolateModel.outputShape[3], 0.0)))
      ];
      // // Run inference
      Interpreter interpreter =
          Interpreter.fromAddress(isolateModel.interpreterAddress);
      interpreter.run(input, output);
      // Get first output tensor
      final result = output.first;

      isolateModel.responsePort.send(result);
    }
  }
}

class InferenceModel {
  CameraImage? cameraImage;
  int interpreterAddress;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.interpreterAddress, this.inputShape,
      this.outputShape);
}
