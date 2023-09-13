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

import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'isolate_inference.dart';

class GestureClassificationHelper {
  static const _modelPath = 'assets/gesture_classification.tflite';
  static const _labelsPath = 'assets/labels.txt';
  late final List<String> _labels;
  late Interpreter _interpreter;
  late final IsolateInference _isolateInference;
  late Tensor _inputTensor;
  late Tensor _outputTensor;

  void _loadModel() async {
    final options = InterpreterOptions();
    // Load model from assets
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    _inputTensor = _interpreter.getInputTensors().first;
    _outputTensor = _interpreter.getOutputTensors().first;
  }

  // load model and labels
  Future<void> init() async {
    _loadModel();
    _loadLabels();
    _isolateInference = IsolateInference();
    await _isolateInference.start();
  }

  Future<void> _loadLabels() async {
    final labelTxt = await rootBundle.loadString(_labelsPath);
    _labels = labelTxt.split(',');
  }

  // inference classification model in separate isolate
  Future<Map<String, double>> _inference(InferenceModel inferenceModel) async {
    ReceivePort responsePort = ReceivePort();
    _isolateInference.sendPort
        .send(inferenceModel..responsePort = responsePort.sendPort);
    // get inference result.
    var results = await responsePort.first;
    return results;
  }

  // inference camera frame
  Future<Map<String, double>> inferenceCameraFrame(
      CameraImage cameraImage) async {
    var isolateModel = InferenceModel(cameraImage, _interpreter.address,
        _labels, _inputTensor.shape, _outputTensor.shape);
    return _inference(isolateModel);
  }

  Future<void> close() async {
    await _isolateInference.close();
    _interpreter.close();
  }
}
