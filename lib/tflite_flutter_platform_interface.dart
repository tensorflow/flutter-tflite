import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tflite_flutter_method_channel.dart';

abstract class TfliteFlutterPlatform extends PlatformInterface {
  /// Constructs a TfliteFlutterPlatform.
  TfliteFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static TfliteFlutterPlatform _instance = MethodChannelTfliteFlutter();

  /// The default instance of [TfliteFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelTfliteFlutter].
  static TfliteFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TfliteFlutterPlatform] when
  /// they register themselves.
  static set instance(TfliteFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
