import 'dart:core';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:movinet/movinet_helper.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_utils.dart';

class IsolateInference {
  final ReceivePort _receivePort = ReceivePort();
  late Isolate _isolate;
  SendPort? _sendPort;

  SendPort? get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn(entryPoint, _receivePort.sendPort);
    _sendPort = await _receivePort.first;
  }

  Future<void> close() async {
    _receivePort.close();
    _isolate.kill();
  }

  // Converting the image to a matrix.
  // shape = 1 x 1 x height x width x 3
  static getImageMatrix(Image inputImage) {
    final imageMatrix = List.generate(
      inputImage.height,
      (y) => List.generate(
        inputImage.width,
        (x) {
          final pixel = inputImage.getPixel(x, y);
          // normalize 0 to 1
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    );

    return [imageMatrix];
  }

  static getImageMatrixUint8(Image inputImage) {
    final imageMatrix = List.generate(
      inputImage.height,
      (y) => List.generate(
        inputImage.width,
        (x) {
          final pixel = inputImage.getPixel(x, y);
          // normalize 0 to 1
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    return [imageMatrix];
  }

  //

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    await for (final InferenceModel message in port) {
      // calculate inference time in ms
      var originalImage = ImageUtils.convertCameraImage(message.cameraImage);

      // rotate image 90 degree in android because android camera is landscape
      if (Platform.isAndroid) {
        originalImage = copyRotate(originalImage!, angle: 90);
      }

      Interpreter interpreter =
          Interpreter.fromAddress(message.interpreterAddress);
      // crop original image to square
      final cropSize = math.min(originalImage!.width, originalImage.height);
      final x = (originalImage.width - cropSize) ~/ 2;
      final y = (originalImage.height - cropSize) ~/ 2;
      final cropImage = copyCrop(originalImage,
          x: x, y: y, width: cropSize, height: cropSize);

      // resize image to map with input shape
      final inputImage = copyResize(cropImage,
          width: message.inputShape[2], height: message.inputShape[3]);

      // convert image to input matrix
      final imageData = getImageMatrix(inputImage);
      final inputData = message.inputState;
      // inputData.entries.iterator;
      inputData[MoviNetHelper.imageInputName] = [imageData];

      // prepare output map for model output
      final outputData = message.outputState;
      // final startTime = DateTime.now().millisecondsSinceEpoch;

      interpreter.runSignature(
          inputData, outputData, MoviNetHelper.signatureKey);

      // finish time
      // final endTime = DateTime.now().millisecondsSinceEpoch;
      // final inferenceTime = endTime - startTime;
      // log("inference time: $inferenceTime ms");
      message.responsePort.send(outputData);
    }
  }
}

class Category {
  final String label;
  final double score;

  Category(this.label, this.score);
}

class InferenceModel {
  CameraImage cameraImage;
  int interpreterAddress;
  List<int> inputShape;
  Map<String, Object> inputState;
  Map<String, Object> outputState;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.interpreterAddress, this.inputShape,
      this.inputState, this.outputState);
}
