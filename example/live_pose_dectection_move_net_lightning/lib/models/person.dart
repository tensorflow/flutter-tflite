import 'dart:convert';

import 'key_point.dart';
import 'rectangle.dart';

class Person {
  final List<KeyPoint> keypoints;
  final Rectangle boundingBox;
  final double score;
  final int? id;

  Person(
    this.keypoints,
    this.boundingBox,
    this.score, {
    this.id,
  });

  @override
  String toString() {
    return 'Person(keypoints: $keypoints, boundingBox: $boundingBox, score: $score, id: $id)';
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'keypoints': keypoints.map((x) => x.toMap()).toList()});
    result.addAll({'boundingBox': boundingBox.toMap()});
    result.addAll({'score': score});
    if (id != null) {
      result.addAll({'id': id});
    }

    return result;
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      List<KeyPoint>.from(map['keypoints']?.map((x) => KeyPoint.fromMap(x))),
      Rectangle.fromMap(map['boundingBox']),
      map['score']?.toDouble() ?? 0.0,
      id: map['id']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));
}
