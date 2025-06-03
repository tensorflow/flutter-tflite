// Flex Additional codes
import 'dart:ffi';
import 'dart:io';

/// TensorFlowLite C library.
// ignore: missing_return
DynamicLibrary tfliteflexlib = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libtensorflowlite_flex_jni.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.process();
  } else {
    throw UnsupportedError("Only Android and iOS platforms are supported.");
  }
}();
