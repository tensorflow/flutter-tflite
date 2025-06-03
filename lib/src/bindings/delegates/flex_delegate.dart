import 'dart:ffi';

import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';

import '../dlib_flex.dart';

// import '../types.dart';

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
