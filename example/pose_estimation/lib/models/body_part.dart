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

enum BodyPart {
  nose(0),
  leftEye(1),
  rightEye(2),
  leftEar(3),
  rightEar(4),
  leftShoulder(5),
  rightShoulder(6),
  leftElbow(7),
  rightElbow(8),
  leftWrist(9),
  rightWrist(10),
  leftHip(11),
  rightHip(12),
  leftKnee(13),
  rightKnee(14),
  leftAnkle(15),
  rightAnkle(16);

  const BodyPart(this.value);

  final int value;
}
