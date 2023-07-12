import 'dart:ui';

/// Singleton to record size related data
class CameraViewSingleton {
  static late double ratio;
  static late Size screenSize;
  static late Size inputImageSize;

  static Size get actualPreviewSize =>
      Size(screenSize.width, screenSize.width * ratio);
}
