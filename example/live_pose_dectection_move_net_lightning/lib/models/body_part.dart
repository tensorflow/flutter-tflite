enum BodyPart {
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

extension BodyPartExt on BodyPart {
  int get value => switch (this) {
        BodyPart.nose => 0,
        BodyPart.leftEye => 1,
        BodyPart.rightEye => 2,
        BodyPart.leftEar => 3,
        BodyPart.rightEar => 4,
        BodyPart.leftShoulder => 5,
        BodyPart.rightShoulder => 6,
        BodyPart.leftElbow => 7,
        BodyPart.rightElbow => 8,
        BodyPart.leftWrist => 9,
        BodyPart.rightWrist => 10,
        BodyPart.leftHip => 11,
        BodyPart.rightHip => 12,
        BodyPart.leftKnee => 13,
        BodyPart.rightKnee => 14,
        BodyPart.leftAnkle => 15,
        BodyPart.rightAnkle => 16,
      };

  static bodyPartFrom(int value) => BodyPart.values[value];
}
