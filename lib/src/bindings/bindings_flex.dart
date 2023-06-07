import 'dart:ffi';

import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';

// Flex Additional codes
import 'dart:io';

/// Author: cpoohee
/// https://github.com/cpoohee/tflite_flutter_plugin
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

// android flex delegate bindings
Pointer<TfLiteDelegate> Function() tfLite_flex_initTensorflow = tfliteflexlib
    .lookup<NativeFunction<_TfLite_flex_initTensorflow_native_t>>(
        'Java_org_tensorflow_lite_flex_FlexDelegate_nativeInitTensorFlow')
    .asFunction();

typedef _TfLite_flex_initTensorflow_native_t = Pointer<TfLiteDelegate>
    Function();

Pointer<TfLiteDelegate> Function() tfLite_flex_createDelegate = tfliteflexlib
    .lookup<NativeFunction<_TfLite_flex_createDelegate_native_t>>(
        'Java_org_tensorflow_lite_flex_FlexDelegate_nativeCreateDelegate')
    .asFunction();

typedef _TfLite_flex_createDelegate_native_t = Pointer<TfLiteDelegate>
    Function();

void Function(Pointer<TfLiteDelegate>) tfLite_flex_deleteDelegate =
    tfliteflexlib
        .lookup<NativeFunction<_TfLite_flex_deleteDelegate_native_t>>(
            'Java_org_tensorflow_lite_flex_FlexDelegate_nativeDeleteDelegate')
        .asFunction();

typedef _TfLite_flex_deleteDelegate_native_t = Void Function(
    Pointer<TfLiteDelegate> delegate);
