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
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:live_object_detection_ssd_mobilenet/tflite/recognition.dart';
import 'package:live_object_detection_ssd_mobilenet/tflite/stats.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  static const String _modelPath = 'assets/models/ssd_mobilenet.tflite';
  static const String _labelPath = 'assets/models/labelmap.txt';

  /// Input size of image (height = width = 300)
  static const int INPUT_SIZE = 300;

  /// Result score threshold
  static const double THRESHOLD = 0.5;
  Interpreter? _interpreter;
  List<String>? _labels;

  get interpreter => _interpreter;

  get labels => _labels;

  Classifier({
    Interpreter? interpreter,
    List<String>? labels,
  }) {
    _loadModel(interpreter: interpreter);
    _loadLabels(labels);
    dev.log('Loading Done.');
  }

  Future<void> _loadModel({Interpreter? interpreter}) async {
    dev.log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    try {
      dev.log('Loading interpreter...');
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            _modelPath,
            options: interpreterOptions..threads = 4,
          );
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  Future<void> _loadLabels(List<String>? labels) async {
    dev.log('Loading labels...');
    _labels = labels ?? (await rootBundle.loadString(_labelPath)).split('\n');
  }

  Map<String, dynamic>? analyseFile(String imagePath) {
    dev.log('Analysing image...');
    // Reading image bytes from file
    final imageData = File(imagePath).readAsBytesSync();

    // Decoding image
    final image = img.decodeImage(imageData);

    return analyseImage(image);
  }

  Map<String, dynamic>? analyseImage(img.Image? image) {
    var predictStartTime = DateTime.now().millisecondsSinceEpoch;

    if (_interpreter == null) {
      dev.log("Interpreter not initialized");
      return null;
    }

    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    /// Pre-process the image
    /// Resizing image fpr model, [300, 300]
    final imageInput = img.copyResize(
      image!,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
    );

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    // Creating matrix representation, [300, 300, 3]
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    final output = _runInference(imageMatrix);

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    dev.log('Processing outputs...');
    // Location
    final locationsRaw = output.first.first as List<List<double>>;

    final List<Rect> locations = locationsRaw
        .map((list) => list.map((value) => (value * INPUT_SIZE)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();
    dev.log('Locations: $locations');

    // Classes
    final classesRaw = output.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();
    dev.log('Classes: $classes');

    // Scores
    final scores = output.elementAt(2).first as List<double>;
    dev.log('Scores: $scores');

    // Number of detections
    final numberOfDetectionsRaw = output.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();
    dev.log('Number of detections: $numberOfDetections');

    dev.log('Classifying detected objects...');
    final List<String> classification = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classification.add(_labels![classes[i]]);
    }
    dev.log('Classes String: $classification');

    /// Generate recognitions
    List<Recognition> recognitions = [];
    for (int i = 0; i < numberOfDetections; i++) {
      // Prediction score
      var score = scores[i];
      // Label string
      var label = classification[i];

      if (score > THRESHOLD) {
        // inverse of rect
        // [locations] corresponds to the image size 300 X 300
        // inverseTransformRect transforms it our [inputImage]
        Rect transformedRect =
            _scaleBox(locations[i], image.height, image.width);

        recognitions.add(
          Recognition(i, label, score, transformedRect),
        );

        /// This can be used for testing purposes only
        // img.drawRect(
        //   image,
        //   x1: transformedRect.left.toInt(),
        //   y1: transformedRect.top.toInt(),
        //   x2: transformedRect.right.toInt(),
        //   y2: transformedRect.bottom.toInt(),
        //   color: img.ColorRgb8(0, 255, 0),
        //   thickness: 3,
        // );
        //
        // // Label drawing
        // img.drawString(
        //   image,
        //   '${classification[i]} ${(scores[i] * 100).round()}%',
        //   font: img.arial24,
        //   x: transformedRect.left.toInt() + 1,
        //   y: transformedRect.top.toInt() + 1,
        //   color: img.ColorRgb8(255, 255, 255),
        // );
      }
    }

    var inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    var predictElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;

    var totalElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;

    dev.log('Recognition Done.');

    return {
      // "image": image,
      "recognitions": recognitions,
      "stats": Stats(
        totalPredictTime: predictElapsedTime,
        totalElapsedTime: totalElapsedTime,
        inferenceTime: inferenceTimeElapsed,
        preProcessingTime: preProcessElapsedTime,
      )
    };
  }

  /// Scaling recognition box in respect with size of preview (image)
  static Rect _scaleBox(Rect box, int height, int width) {
    final double x1 = box.left;
    final double y1 = box.top;
    final double x2 = box.right;
    final double y2 = box.bottom;
    final double scaleX = width / INPUT_SIZE;
    final double scaleY = height / INPUT_SIZE;
    final double xDelta = (x2 - x1) * scaleX;
    final double yDelta = (y2 - y1) * scaleY;
    return Rect.fromLTRB(
      x1 * scaleX,
      y1 * scaleY,
      x1 * scaleX + xDelta,
      y1 * scaleY + yDelta,
    );
  }

  List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    dev.log('Running inference...');

    // Set input tensor [1, 300, 300, 3]
    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0],
    };

    _interpreter!.runForMultipleInputs([input], output);
    return output.values.toList();
  }
}
