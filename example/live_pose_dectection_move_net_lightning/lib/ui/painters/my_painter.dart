import 'dart:math';

import 'package:flutter/material.dart';
import 'package:live_pose_dectection_move_net_lightning/models/person.dart';

const Map<List<int>, Color> keypointEdgeIndToColor = {
  [0, 1]: Color.fromRGBO(147, 20, 255, 1),
  [0, 2]: Color.fromRGBO(255, 255, 0, 1),
  [1, 3]: Color.fromRGBO(147, 20, 255, 1),
  [2, 4]: Color.fromRGBO(255, 255, 0, 1),
  [0, 5]: Color.fromRGBO(147, 20, 255, 1),
  [0, 6]: Color.fromRGBO(255, 255, 0, 1),
  [5, 7]: Color.fromRGBO(147, 20, 255, 1),
  [7, 9]: Color.fromRGBO(147, 20, 255, 1),
  [6, 8]: Color.fromRGBO(255, 255, 0, 1),
  [8, 10]: Color.fromRGBO(255, 255, 0, 1),
  [5, 6]: Color.fromRGBO(0, 255, 255, 1),
  [5, 11]: Color.fromRGBO(147, 20, 255, 1),
  [6, 12]: Color.fromRGBO(255, 255, 0, 1),
  [11, 12]: Color.fromRGBO(0, 255, 255, 1),
  [11, 13]: Color.fromRGBO(147, 20, 255, 1),
  [13, 15]: Color.fromRGBO(147, 20, 255, 1),
  [12, 14]: Color.fromRGBO(255, 255, 0, 1),
  [14, 16]: Color.fromRGBO(255, 255, 0, 1)
};

const List<Color> colorList = [
  Color.fromRGBO(47, 79, 79, 1),
  Color.fromRGBO(139, 69, 19, 1),
  Color.fromRGBO(0, 128, 0, 1),
  Color.fromRGBO(0, 0, 139, 1),
  Color.fromRGBO(255, 0, 0, 1),
  Color.fromRGBO(255, 215, 0, 1),
  Color.fromRGBO(0, 255, 0, 1),
  Color.fromRGBO(0, 255, 255, 1),
  Color.fromRGBO(255, 0, 255, 1),
  Color.fromRGBO(30, 144, 255, 1),
  Color.fromRGBO(255, 228, 181, 1),
  Color.fromRGBO(255, 105, 180, 1),
];

class MyPainter extends CustomPainter {
  MyPainter({
    required this.listPersons,
    this.keypointColor,
    this.keypointThreshold = 0.05,
    this.instanceThreshold = 0.1,
  });

  final List<Person> listPersons;
  final Color? keypointColor;
  double keypointThreshold = 0.02;
  double instanceThreshold = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (final person in listPersons) {
      if (person.score < instanceThreshold) continue;
      final keypoints = person.keypoints;
      final boundingBox = person.boundingBox;

      Color personColor;
      if (keypointColor == null) {
        if (person.id == null) {
          personColor = const Color.fromRGBO(0, 255, 0, 1);
        } else {
          personColor = colorList[person.id! % colorList.length];
        }
      } else {
        personColor = keypointColor!;
      }

      for (var i = 0; i < keypoints.length; i++) {
        if (keypoints[i].score >= keypointThreshold) {
          final point = keypoints[i].coordinate;
          canvas.drawCircle(
            Offset(point.x, point.y),
            4,
            Paint()..color = personColor,
          );
        }
      }

      for (final edgePair in keypointEdgeIndToColor.keys) {
        final edgeColor = keypointEdgeIndToColor[edgePair];

        if (keypoints[edgePair[0]].score > keypointThreshold &&
            keypoints[edgePair[1]].score > keypointThreshold) {
          final startPoint = keypoints[edgePair[0]].coordinate;
          final endPoint = keypoints[edgePair[1]].coordinate;
          _drawDashedLine(
            canvas,
            Offset(startPoint.x, startPoint.y),
            Offset(endPoint.x, endPoint.y),
            Paint()
              ..strokeWidth = 1
              ..color = edgeColor!
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.miter,
          );
        }
      }

      final startPoint = boundingBox.startPoint;
      final endPoint = boundingBox.endPoint;
      canvas.drawRect(
        Rect.fromPoints(
          Offset(startPoint.x, startPoint.y),
          Offset(
            endPoint.x,
            endPoint.y,
          ),
        ),
        Paint()
          ..color = personColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.listPersons != listPersons &&
            oldDelegate.listPersons.first.score != listPersons.first.score ||
        keypointColor != oldDelegate.keypointColor;
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const int dashWidth = 4;
    const int dashSpace = 4;

    // Get normalized distance vector
    var dx = p2.dx - p1.dx;
    var dy = p2.dy - p1.dy;
    final magnitude = sqrt(dx * dx + dy * dy);
    final steps = magnitude ~/ (dashWidth + dashSpace);
    dx = dx / magnitude;
    dy = dy / magnitude;
    var startX = p1.dx;
    var startY = p1.dy;

    for (int i = 0; i < steps; i++) {
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + dx * dashWidth, startY + dy * dashWidth), paint);
      startX += dx * (dashWidth + dashSpace);
      startY += dy * (dashWidth + dashSpace);
    }
  }
}
