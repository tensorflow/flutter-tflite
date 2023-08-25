class QaAnswer {
  Pos pos;
  String text;

  QaAnswer({required this.pos, required this.text});
}

class Pos implements Comparable<Pos> {
  int start;
  int end;
  double logit;

  Pos({required this.start, required this.end, required this.logit});

  @override
  int compareTo(Pos other) {
    return other.logit.compareTo(logit);
  }
}
