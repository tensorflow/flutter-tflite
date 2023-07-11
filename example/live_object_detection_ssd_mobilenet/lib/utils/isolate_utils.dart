import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageLib;
import 'package:live_object_detection_ssd_mobilenet/tflite/classifier.dart';
import 'package:live_object_detection_ssd_mobilenet/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = 'InferenceIsolate';

  late Isolate _isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first as SendPort;
  }

  void finish() {
    _isolate.kill();
    _receivePort.close();
  }

  static Future<void> entryPoint(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic data) {
      final isolateData = data as IsolateData;
      final Classifier classifier = Classifier(
        interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
        labels: isolateData.labels,
      );
      convertCameraImageToImage(isolateData.cameraImage).then((image) {
        if (image != null) {
          if (Platform.isAndroid) {
            image = imageLib.copyRotate(image, angle: 90);
          }
          final results = classifier.analyseImage(image);
          isolateData.responsePort.send(results);
        }
      });
    });
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  IsolateData(
    this.cameraImage,
    this.interpreterAddress,
    this.labels,
  );

  CameraImage cameraImage;
  int interpreterAddress;
  List<String> labels;
  late SendPort responsePort;
}
