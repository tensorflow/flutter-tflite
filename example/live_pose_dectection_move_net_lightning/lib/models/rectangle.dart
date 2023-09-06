import 'dart:convert';

import 'point.dart';

class Rectangle {
  final Point startPoint;
  final Point endPoint;

  Rectangle(this.startPoint, this.endPoint);

  @override
  String toString() =>
      'Rectangle(startPoint: $startPoint, endPoint: $endPoint)';

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'startPoint': startPoint.toMap()});
    result.addAll({'endPoint': endPoint.toMap()});

    return result;
  }

  factory Rectangle.fromMap(Map<String, dynamic> map) {
    return Rectangle(
      Point.fromMap(map['startPoint']),
      Point.fromMap(map['endPoint']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Rectangle.fromJson(String source) =>
      Rectangle.fromMap(json.decode(source));
}
