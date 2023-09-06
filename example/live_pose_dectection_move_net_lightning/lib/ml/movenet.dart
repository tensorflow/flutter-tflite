import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:live_pose_dectection_move_net_lightning/models/body_part.dart';
import 'package:live_pose_dectection_move_net_lightning/models/key_point.dart';
import 'package:live_pose_dectection_move_net_lightning/models/person.dart';
import 'package:live_pose_dectection_move_net_lightning/models/point.dart';
import 'package:live_pose_dectection_move_net_lightning/models/rectangle.dart';
import 'package:live_pose_dectection_move_net_lightning/models/screen_params.dart';
import 'package:live_pose_dectection_move_net_lightning/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Movenet {
  static const double minCropKeypointScore = 0.2;
  static const double torsoExpansionRatio = 1.9;
  static const double bodyExpansionRatio = 1.2;

  late Interpreter _interpreter;
  late int _inputIndex;
  late int _inputHeight;
  late int _inputWidth;
  Map<String, double>? _cropRegion;

  StreamController<Person?>? resultsStream;

  Future<void> getModel() async {
    resultsStream = StreamController<Person?>();
    final options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(
      'assets/models/movenet_lightning.tflite',
      options: options,
    );
    _interpreter.allocateTensors();
    _inputIndex = 0;

    _inputHeight = _interpreter.getInputTensor(_inputIndex).shape[1];
    _inputWidth = _interpreter.getInputTensor(_inputIndex).shape[2];
  }

  Map<String, double> initCropRegion(double imageHeight, double imageWidth) {
    double yMin;
    double boxHeight;
    double xMin;
    double boxWidth;
    if (imageWidth > imageHeight) {
      xMin = 0.0;
      boxWidth = 1.0;
      yMin = (imageHeight / 2 - imageWidth / 2) / imageHeight;
      boxHeight = imageWidth / imageHeight;
    } else {
      yMin = 0.0;
      boxHeight = 1.0;
      xMin = (imageWidth / 2 - imageHeight / 2) / imageWidth;
      boxWidth = imageHeight / imageWidth;
    }
    return {
      'y_min': yMin,
      'x_min': xMin,
      'y_max': yMin + boxHeight,
      'x_max': xMin + boxWidth,
      'height': boxHeight,
      'width': boxWidth,
    };
  }

  bool _torsoVisible(List<List<num>> keypoints) {
    double leftHipScore = keypoints[BodyPart.leftHip.value][2].toDouble();
    double rightHipScore = keypoints[BodyPart.rightHip.value][2].toDouble();
    double leftShoulderScore =
        keypoints[BodyPart.leftShoulder.value][2].toDouble();
    double rightShoulderScore =
        keypoints[BodyPart.rightShoulder.value][2].toDouble();

    bool leftHipVisible = leftHipScore > minCropKeypointScore;
    bool rightHipVisible = rightHipScore > minCropKeypointScore;
    bool leftShoulderVisible = leftShoulderScore > minCropKeypointScore;
    bool rightShoulderVisible = rightShoulderScore > minCropKeypointScore;

    return (leftHipVisible || rightHipVisible) &&
        (leftShoulderVisible || rightShoulderVisible);
  }

  (double, double, double, double) _determineTorsoAndBodyRange(
    List<List<num>> keypoints,
    Map<BodyPart, Point> targetKeypoints,
    double centerY,
    double centerX,
  ) {
    final torsoJoints = [
      BodyPart.leftShoulder,
      BodyPart.rightShoulder,
      BodyPart.leftHip,
      BodyPart.rightHip
    ];

    double maxTorsoYRange = 0.0;
    double maxTorsoXRange = 0.0;

    for (final joint in torsoJoints) {
      final distY = (centerY - targetKeypoints[joint]!.y).abs();
      final distX = (centerX - targetKeypoints[joint]!.x).abs();
      maxTorsoYRange = math.max(maxTorsoYRange, distY);
      maxTorsoXRange = math.max(maxTorsoXRange, distX);
    }

    double maxBodyYRange = 0.0;
    double maxBodyXRange = 0.0;

    for (int idx = 0; idx < BodyPart.values.length; idx++) {
      final bodyPart = BodyPart.values[idx];
      if (keypoints[bodyPart.value][2] < minCropKeypointScore) {
        continue;
      }
      final distY = (centerY - targetKeypoints[bodyPart]!.y).abs();
      final distX = (centerX - targetKeypoints[bodyPart]!.x).abs();

      maxBodyYRange = math.max(maxBodyYRange, distY);
      maxBodyXRange = math.max(maxBodyXRange, distX);
    }

    return (
      maxTorsoYRange,
      maxTorsoXRange,
      maxBodyYRange,
      maxBodyXRange,
    );
  }

  Map<String, double> _determineCropRegion(
    List<List<num>> keypoints,
    double imageHeight,
    double imageWidth,
  ) {
    final targetKeypoints = <BodyPart, Point>{};
    for (int idx = 0; idx < BodyPart.values.length; idx++) {
      final bodyPart = BodyPart.values[idx];
      double keypointY = keypoints[bodyPart.value][0] * imageHeight;
      double keypointX = keypoints[bodyPart.value][1] * imageWidth;
      targetKeypoints[bodyPart] = Point(keypointX, keypointY);
    }

    if (_torsoVisible(keypoints)) {
      final centerYPixel = (targetKeypoints[BodyPart.leftHip]!.y +
              targetKeypoints[BodyPart.rightHip]!.y) /
          2;
      final centerXPixel = (targetKeypoints[BodyPart.leftHip]!.x +
              targetKeypoints[BodyPart.rightHip]!.x) /
          2;

      final (
        maxTorsoYRange,
        maxTorsoXRange,
        maxBodyYRange,
        maxBodyXRange,
      ) = _determineTorsoAndBodyRange(
        keypoints,
        targetKeypoints,
        centerYPixel,
        centerXPixel,
      );

      double cropLengthHalf = [
        maxTorsoYRange * Movenet.torsoExpansionRatio,
        maxTorsoXRange * Movenet.torsoExpansionRatio,
        maxBodyYRange * Movenet.bodyExpansionRatio,
        maxBodyXRange * Movenet.bodyExpansionRatio,
      ].reduce(math.max);

      final distancesToBorder = <double>[
        centerXPixel,
        imageWidth - centerXPixel,
        centerYPixel,
        imageHeight - centerYPixel
      ];
      cropLengthHalf =
          math.min(cropLengthHalf, distancesToBorder.reduce(math.max));

      if (cropLengthHalf > math.max(imageWidth, imageHeight) / 2) {
        return initCropRegion(imageHeight, imageWidth);
      } else {
        final cropLength = cropLengthHalf * 2;
        final cropCorner = Point(
          centerXPixel - cropLengthHalf,
          centerYPixel - cropLengthHalf,
        );
        return {
          'y_min': cropCorner.y / imageHeight,
          'x_min': cropCorner.x / imageWidth,
          'y_max': (cropCorner.y + cropLength) / imageHeight,
          'x_max': (cropCorner.x + cropLength) / imageWidth,
          'height': ((cropCorner.y + cropLength) / imageHeight) -
              (cropCorner.y / imageHeight),
          'width': ((cropCorner.x + cropLength) / imageWidth) -
              (cropCorner.x / imageWidth)
        };
      }
    } else {
      return initCropRegion(imageHeight, imageWidth);
    }
  }

  img.Image _cropAndResize(
    Map<String, double> cropRegion,
    img.Image inputImage,
  ) {
    double yMin = cropRegion['y_min']!;
    double xMin = cropRegion['x_min']!;
    double yMax = cropRegion['y_max']!;
    double xMax = cropRegion['x_max']!;

    final cropTop = (yMin < 0) ? 0 : yMin * inputImage.height;
    final cropBottom =
        (yMax >= 1) ? inputImage.height : yMax * inputImage.height;
    final cropLeft = (xMin < 0) ? 0 : xMin * inputImage.width;
    final cropRight = (xMax >= 1) ? inputImage.width : xMax * inputImage.width;
    final paddingTop = yMin < 0 ? 0 - yMin * inputImage.height : 0;
    final paddingBottom = (yMax >= 1) ? (yMax - 1) * inputImage.height : 0;
    final paddingLeft = xMin < 0 ? (0 - xMin) * inputImage.width : 0;
    final paddingRight = xMax >= 1 ? (xMax - 1) * inputImage.width : 0;
    var outputImage = img.copyCrop(
      inputImage,
      x: cropLeft.toInt(),
      y: cropTop.toInt(),
      width: (cropRight - cropLeft).toInt(),
      height: (cropBottom - cropTop).toInt(),
    );

    final color = img.ColorRgb8(255, 255, 255);

    outputImage = copyMakeBorder(
      outputImage,
      paddingTop.toInt(),
      paddingBottom.toInt(),
      paddingLeft.toInt(),
      paddingRight.toInt(),
      color,
    );

    outputImage = img.copyResize(
      outputImage,
      width: _inputWidth,
      height: _inputHeight,
    );

    // outputImage = convertToRGB(outputImage);

    return outputImage;
  }

  List<List<double>> _runDetector(
    img.Image inputImage,
    Map<String, double> cropRegion,
  ) {
    final image = _cropAndResize(_cropRegion!, inputImage);

    var keypointsWithScores = [
      [
        List<List<num>>.filled(
          17,
          List<num>.filled(3, 0),
        ),
      ]
    ];

    _interpreter.run(
      image.buffer,
      keypointsWithScores,
    );
    final keypointsWithScoresArray = keypointsWithScores.toList().first.first;
    for (int idx = 0; idx < BodyPart.values.length; idx++) {
      keypointsWithScoresArray[idx][0] = cropRegion['y_min']! +
          cropRegion['height']! * keypointsWithScoresArray[idx][0];
      keypointsWithScoresArray[idx][1] = cropRegion['x_min']! +
          cropRegion['width']! * keypointsWithScoresArray[idx][1];
    }
    return keypointsWithScoresArray as List<List<double>>;
  }

  Future<void> detectPerson(
    CameraImage cameraImage,
  ) async {
    var image = await convertCameraImageToImage(cameraImage);
    if (image == null) return;
    if (Platform.isAndroid) {
      image = img.copyRotate(image, angle: 90);
    }
    _cropRegion ??= initCropRegion(
      image.height.toDouble(),
      image.width.toDouble(),
    );
    List<List<double>> keypointsWithUpdatedPositions = _runDetector(
      image,
      _cropRegion!,
    );

    _cropRegion = _determineCropRegion(
      keypointsWithUpdatedPositions,
      image.height.toDouble(),
      image.width.toDouble(),
    );
    resultsStream?.add(
      personFromKeypointsWithScores(
        keypointsWithUpdatedPositions,
        image.height.toDouble() / ScreenParams.previewRatio * 0.96,
        image.width.toDouble() / ScreenParams.previewRatio * 0.94,
      ),
    );
  }

  Person personFromKeypointsWithScores(
    List<List<double>> keypointsWithScores,
    double imageHeight,
    double imageWidth, {
    double keypointScoreThreshold = 0.4,
  }) {
    List<double> kptsX = keypointsWithScores
        .map((e) => e[1])
        .toList()
        .map((e) => e.toDouble())
        .toList();

    List<double> kptsY = keypointsWithScores
        .map((e) => e[0])
        .toList()
        .map((e) => e.toDouble())
        .toList();

    List<double> scores = keypointsWithScores
        .map((e) => e[2])
        .toList()
        .map((e) => e.toDouble())
        .toList();

    List<KeyPoint> keypoints = [];
    for (int i = 0; i < scores.length; i++) {
      keypoints.add(
        KeyPoint(
          BodyPart.values[i],
          Point(
            kptsX[i] * imageWidth,
            kptsY[i] * imageHeight,
          ),
          scores[i],
        ),
      );
    }

    double minKptsX = kptsX.reduce(math.min);
    double minKptsY = kptsY.reduce(math.min);
    double maxKptsX = kptsX.reduce(math.max);
    double maxKptsY = kptsY.reduce(math.max);

    Rectangle boundingBox = Rectangle(
      Point(
        minKptsX * imageWidth,
        minKptsY * imageHeight,
      ),
      Point(
        maxKptsX * imageWidth,
        maxKptsY * imageHeight,
      ),
    );

    List<double> scoresAboveThreshold = scores
        .where(
          (score) => score > keypointScoreThreshold,
        )
        .toList();
    double personScore = scoresAboveThreshold.isNotEmpty
        ? scoresAboveThreshold.reduce(
              (sum, score) => sum + score,
            ) /
            scoresAboveThreshold.length
        : 0.0;

    return Person(
      keypoints,
      boundingBox,
      personScore,
    );
  }

  void close() {
    resultsStream?.sink.close();
    _interpreter.close();
  }
}
