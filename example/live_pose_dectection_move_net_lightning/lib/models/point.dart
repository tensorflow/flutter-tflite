import 'dart:convert';

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  @override
  String toString() => 'Point(x: $x, y: $y)';

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'x': x});
    result.addAll({'y': y});

    return result;
  }

  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      map['x']?.toDouble() ?? 0.0,
      map['y']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Point.fromJson(String source) => Point.fromMap(json.decode(source));
}
