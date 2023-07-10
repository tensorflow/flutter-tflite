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
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ObjectDetection03 {
  static const String _modelPath = 'assets/models/yolox_nano_with_post_float32.tflite';
  static const String _labelPath = 'assets/models/labels.txt';

  Interpreter? _interpreter;
  List<String>? _labels;
  String _lastScore = "NaN";

  ObjectDetection03() {
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    final interpreterOptions = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(_modelPath, options: interpreterOptions);
    List<Tensor>? inputTensor = _interpreter?.getInputTensors();
    List<Tensor>? outputTensor = _interpreter?.getOutputTensors();
    print(inputTensor);
    print(outputTensor);
  }

  Future<void> _loadLabels() async {
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');
  }

  Uint8List analyseImage(Uint8List imageData) {
    final image = img.decodeImage(imageData.buffer.asUint8List())!;
    final imageInput = img.copyResize(image, width: 416, height: 416);
    Uint8List byte = imageToByteListFloat32(imageInput, 416, 127.5, 127.5);
    final output = {0: List<List<num>>.filled(16, List<num>.filled(7, 0))};
    _interpreter!.runForMultipleInputs([byte], output);
    final elements = output.values.toList().elementAt(0);
    List<num> allValue = [];
    for (var element in elements) {
      allValue.add(element.elementAt(2));
    }
    num max = allValue.reduce((value, element) => value > element ? value : element);
    int maxIndex = allValue.indexOf(max);
    _lastScore = '$max ---> $maxIndex';
    print(_lastScore);
    return imageData;
  }

  String getLastScore() {
    return _lastScore;
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
