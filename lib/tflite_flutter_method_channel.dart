import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tflite_flutter_platform_interface.dart';

/// An implementation of [TfliteFlutterPlatform] that uses method channels.
class MethodChannelTfliteFlutter extends TfliteFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tflite_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
