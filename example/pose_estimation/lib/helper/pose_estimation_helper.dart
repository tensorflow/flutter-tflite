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
import 'package:pose_estimation/models/person.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'isolate_inference.dart';

class PoseEstimationHelper {
  late final Interpreter _interpreter;
  late final Tensor _inputTensor;
  late final IsolateInference _isolateInference;

  _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/posenet_mobilenet.tflite');
    _inputTensor = _interpreter.getInputTensors().first;
  }

  initHelper() async {
    await _loadModel();
    _isolateInference = IsolateInference();
    await _isolateInference.start();
  }

  Future<Person> estimatePoses(CameraImage cameraImage) async {
    final isolateModel =
        InferenceModel(cameraImage, _interpreter.address, _inputTensor.shape);
    ReceivePort responsePort = ReceivePort();
    _isolateInference.sendPort
        ?.send(isolateModel..responsePort = responsePort.sendPort);
    // get inference result.
    return await responsePort.first;
  }

  close() {
    _interpreter.close();
  }
}
