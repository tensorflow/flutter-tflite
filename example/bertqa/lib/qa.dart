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
