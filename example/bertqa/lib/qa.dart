class QA {
  List<String>? titles;
  List<String>? contents;
  List<List<String>>? questions;

  QA({this.titles, this.contents, this.questions});

  QA.fromJson(Map<String, dynamic> map) {
    titles = (map['titles'] as List<dynamic>)
        .map((e) => (e as List<dynamic>)[0] as String)
        .toList();
    contents = (map['contents'] as List<dynamic>)
        .map((e) => (e as List<dynamic>)[0] as String)
        .toList();
    questions = (map['questions'] as List<dynamic>)
        .map((e) => (e as List<dynamic>).cast<String>())
        .toList();
  }
}
