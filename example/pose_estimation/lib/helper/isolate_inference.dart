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
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../image_utils.dart';
import '../models/body_part.dart';
import '../models/key_point.dart';
import '../models/person.dart';

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
  static getImageMatrix(Image inputImage) {
    final imageMatrix = List.generate(
      inputImage.height,
      (y) => List.generate(
        inputImage.width,
        (x) {
          final pixel = inputImage.getPixel(x, y);
          // normalize -1 to 1
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5
          ];
        },
      ),
    );

    return [imageMatrix];
  }

  // Preparing the output map for the model.
  static Map<int, Object> prepareOutput() {
    // outputmap
    final outputMap = <int, Object>{};

    // 1 * 9 * 9 * 17 contains heatmaps
    outputMap[0] = [List.filled(9, List.filled(9, List.filled(17, 0.0)))];

    // 1 * 9 * 9 * 34 contains offsets
    outputMap[1] = [List.filled(9, List.filled(9, List.filled(34, 0.0)))];

    // 1 * 9 * 9 * 32 contains forward displacements
    outputMap[2] = [List.filled(9, List.filled(9, List.filled(32, 0.0)))];

    // 1 * 9 * 9 * 32 contains backward displacements
    outputMap[3] = [List.filled(9, List.filled(9, List.filled(32, 0.0)))];

    return outputMap;
  }

  static sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  // Post-processing the model outputs to get the keypoint coordinates and the confidence scores.
  static Person postProcessModelOutputs(
      List<List<List<List<double>>>> heatMap,
      List<List<List<List<double>>>> offsets,
      int inputImageWidth,
      int inputImageHeight,
      int originalWidth,
      int originalHeight,
      double ratio) {
    final height = heatMap[0].length;
    final width = heatMap[0][0].length;
    final numKeypoints = heatMap[0][0][0].length;

    final keypointPositions = <List<int>>[];
    for (var keypoint = 0; keypoint < numKeypoints; keypoint++) {
      var maxVal = heatMap[0][0][0][keypoint];
      var maxRow = 0;
      var maxCol = 0;

      // Finding the max keypoint value in the heatmap across all locations.
      for (var row = 0; row < height; row++) {
        for (var col = 0; col < width; col++) {
          if (heatMap[0][row][col][keypoint] > maxVal) {
            maxVal = heatMap[0][row][col][keypoint];
            maxRow = row;
            maxCol = col;
          }
        }
      }
      keypointPositions.add([maxRow, maxCol]);
    }

    // Calculating the x and y coordinates of the keypoints with offset adjustment.
    final xCoords = List.filled(numKeypoints, 0.0);
    final yCoords = List.filled(numKeypoints, 0.0);
    final confidenceScores = List.filled(numKeypoints, 0.0);
    for (var idx = 0; idx < keypointPositions.length; idx++) {
      final positionY = keypointPositions[idx][0];
      final positionX = keypointPositions[idx][1];

      final inputImageCoordinateY =
          positionY / (height - 1.0) * inputImageHeight +
              offsets[0][positionY][positionX][idx];
      final double ratioHeight = originalHeight / inputImageHeight;
      yCoords[idx] = inputImageCoordinateY * ratioHeight;

      final inputImageCoordinateX =
          positionX / (width - 1.0) * inputImageWidth +
              offsets[0][positionY][positionX][idx + numKeypoints];
      final double ratioWidth = originalWidth / inputImageWidth;
      xCoords[idx] = inputImageCoordinateX * ratioWidth;

      confidenceScores[idx] = sigmoid(heatMap[0][positionY][positionX][idx]);
    }
    final keypointList = <KeyPoint>[];
    var totalScore = 0.0;

    // Calculating the total score of all keypoints.
    for (var value in BodyPart.values) {
      totalScore += confidenceScores[value.index];
      keypointList.add(KeyPoint(
          bodyPart: value,
          coordinate: Offset(xCoords[value.index], yCoords[value.index]),
          score: confidenceScores[value.index]));
    }
    return Person(keyPoints: keypointList, score: totalScore / numKeypoints);
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    await for (final InferenceModel message in port) {
      var originalImage = ImageUtils.convertCameraImage(message.cameraImage);

      // rotate image 90 degree in android because android camera is landscape
      if (Platform.isAndroid) {
        originalImage = copyRotate(originalImage!, angle: 90);
      }

      // resize image to map with input shape
      final inputImage = copyResize(originalImage!,
          width: message.inputShape[2], height: message.inputShape[1]);

      // convert image to input matrix
      final inputData = getImageMatrix(inputImage);

      // prepare output map for model output
      final outputData = prepareOutput();

      Interpreter interpreter =
          Interpreter.fromAddress(message.interpreterAddress);
      interpreter.runForMultipleInputs([inputData], outputData);

      final heatMap = outputData[0] as List<List<List<List<double>>>>;
      final offsets = outputData[1] as List<List<List<List<double>>>>;

      final person = postProcessModelOutputs(heatMap, offsets, inputImage.width,
          inputImage.height, originalImage.width, originalImage.height, 0);
      message.responsePort.send(person);
    }
  }
}

class InferenceModel {
  CameraImage cameraImage;
  int interpreterAddress;
  List<int> inputShape;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.interpreterAddress, this.inputShape);
}
