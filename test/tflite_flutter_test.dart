import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter_platform_interface.dart';
import 'package:tflite_flutter/tflite_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock platform that never touches the native dylib.
class MockTfliteFlutterPlatform with MockPlatformInterfaceMixin implements TfliteFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TfliteFlutterPlatform initialPlatform = TfliteFlutterPlatform.instance;

  setUp(() {
    // Replace the real platform (which loads the dylib) with the mock.
    TfliteFlutterPlatform.instance = MockTfliteFlutterPlatform();
  });

  tearDown(() {
    // Restore so other test files are not affected.
    TfliteFlutterPlatform.instance = initialPlatform;
  });

  test('MethodChannelTfliteFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTfliteFlutter>());
  });

  test('getPlatformVersion returns mocked value', () async {
    final version = await TfliteFlutterPlatform.instance.getPlatformVersion();
    expect(version, '42');
  });
}
