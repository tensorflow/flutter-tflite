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
