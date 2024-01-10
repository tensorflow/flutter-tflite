import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'isolate_inference.dart';

class MoviNetHelper {
  static const String signatureKey = "serving_default";
  static const String imageInputName = "image";
  static const String logitsOutputName = "logits";
  late final Interpreter _interpreter;
  late IsolateInference _isolateInference;
  late final List<int> _inputShape;
  late final int outputCategoryCount;
  late List<String> _labels;
  late Map<String, Object> _inputState;
  bool isUpdate = false;

  clearState() async {
    isUpdate = true;
  }

  Future<void> loadLabels() async {
    final labelsRaw =
        await rootBundle.loadString('assets/label/kinetics600_label_map.txt');
    _labels = labelsRaw.split('\n');
  }

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/movinet_int8.tflite');
  }

  Future<void> initHelper() async {
    await loadModel();
    await loadLabels();
    _inputShape =
        _interpreter.getSignatureInputTensorShape(signatureKey, imageInputName);
    outputCategoryCount = _interpreter.getSignatureOutputTensorShape(
        signatureKey, logitsOutputName)[1];
    await createNewSession();
  }

  Future<void> createNewSession() async {
    _inputState = initializeInput(_interpreter);
    _isolateInference = IsolateInference();
    await _isolateInference.start();
    dev.log("create new session");
  }

  Future<Category> classify(CameraImage cameraImage) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    final outputState = initializeOutput(_interpreter);
    final isolateModel = InferenceModel(cameraImage, _interpreter.address,
        _inputShape, _inputState, outputState);
    ReceivePort responsePort = ReceivePort();
    _isolateInference.sendPort
        ?.send(isolateModel..responsePort = responsePort.sendPort);
    final resultOutput = await responsePort.first as Map<String, Object>;
    final categories = postprocessOutputLogits(
        (resultOutput[logitsOutputName] as List<Object>).first as List<double>);
    resultOutput.remove(logitsOutputName);
    dev.log("set output");
    if (isUpdate) {
      isUpdate = false;
      _inputState = initializeInput(_interpreter);
    } else {
      _inputState = resultOutput;
    }
    // sort categories by descending score
    categories.sort((a, b) => b.score.compareTo(a.score));
    final end = DateTime.now().millisecondsSinceEpoch;
    dev.log("inference time: ${end - start} ms");
    // dev.log("message ${categories.first.label}");

    return categories.first;
  }

  close() {
    _interpreter.close();
  }

  List<Category> postprocessOutputLogits(List<double> logits) {
    final probabilities = softmax(logits);
    final categories = <Category>[];
    for (int i = 0; i < probabilities.length; i++) {
      categories.add(Category(_labels[i], probabilities[i]));
    }
    return categories;
  }

  static List<double> softmax(List<double> logits) {
    double max = 0;
    double sum = 0;
    for (int i = 0; i < logits.length; i++) {
      if (logits[i] > max) {
        max = logits[i];
      }
    }
    for (int i = 0; i < logits.length; i++) {
      logits[i] = exp(logits[i] - max);
      sum += logits[i];
    }
    for (int i = 0; i < logits.length; i++) {
      logits[i] /= sum;
    }
    return logits;
  }

  static Map<String, Object> initializeInput(Interpreter interpreter) {
    final inputs = HashMap<String, Object>();
    for (int i = 0;
        i < interpreter.getSignatureInputCount(MoviNetHelper.signatureKey);
        i++) {
      final inputName =
          interpreter.getSignatureInputName(MoviNetHelper.signatureKey, i);
      // Skip the input image tensor as it'll be fed in later.
      if (inputName == MoviNetHelper.imageInputName) {
        continue;
      }
      final shape = interpreter.getSignatureInputTensorShape(
          MoviNetHelper.signatureKey, inputName);

      /// debug
      ///
      // if (inputName == "state_block3_layer1_stream_buffer") {
      //   dev.log("debug $shape");
      // }
      inputs[inputName] = createShapeData(shape);
    }
    return inputs;
  }

  // static ByteBuffer getImageMatrix(CameraImage image) {
  //   final convertedBytes = ByteData(image.planes[0].bytes.length);
  //   int pixelIndex = 0;
  //   for (int i = 0; i < image.height; i++) {
  //     for (int j = 0; j < image.width; j++, pixelIndex += 3) {
  //       final int pixel = image.planes[0].bytes[pixelIndex];
  //       convertedBytes.setUint8(pixelIndex, pixel);
  //       convertedBytes.setUint8(pixelIndex + 1, pixel);
  //       convertedBytes.setUint8(pixelIndex + 2, pixel);
  //     }
  //   }
  //   return convertedBytes.buffer;
  // }

  static Uint8List createShapeDataByte(List<int> shape, int byteSize) {
    int dataSize = 1;
    for (int i = 0; i < shape.length; i++) {
      dataSize *= shape[i];
    }
    dataSize *= byteSize;
    return Uint8List.fromList(List.filled(dataSize, 0));
    // return ByteData(dataSize).buffer;
  }

  static List<Object> createShapeData(List<int> shape) {
    if (shape.length == 1) {
      return List.filled(shape.first, 0);
    }
    return List.generate(
        shape.first, (index) => createShapeData(shape.sublist(1)));
  }

  static Map<String, Object> initializeOutput(Interpreter interpreter) {
    final outputs = HashMap<String, Object>();
    for (int i = 0;
        i < interpreter.getSignatureOutputCount(MoviNetHelper.signatureKey);
        i++) {
      final outputName =
          interpreter.getSignatureOutputName(MoviNetHelper.signatureKey, i);
      final shape = interpreter.getSignatureOutputTensorShape(
          MoviNetHelper.signatureKey, outputName);
      outputs[outputName] = createShapeData(shape);
    }
    return outputs;
  }
}
