import 'dart:convert';

import 'body_part.dart';
import 'point.dart';

class KeyPoint {
  final BodyPart bodyPart;
  final Point coordinate;
  final double score;

  KeyPoint(
    this.bodyPart,
    this.coordinate,
    this.score,
  );

  @override
  String toString() =>
      'KeyPoint(bodyPart: $bodyPart, coordinate: $coordinate, score: $score)';

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'bodyPart': bodyPart.value});
    result.addAll({'coordinate': coordinate.toMap()});
    result.addAll({'score': score});

    return result;
  }

  factory KeyPoint.fromMap(Map<String, dynamic> map) {
    return KeyPoint(
      BodyPartExt.bodyPartFrom(map['bodyPart']),
      Point.fromMap(map['coordinate']),
      map['score']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory KeyPoint.fromJson(String source) =>
      KeyPoint.fromMap(json.decode(source));
}
