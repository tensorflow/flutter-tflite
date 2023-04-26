import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'dlib.dart';
import 'types.dart';

/// Returns a model from the provided buffer, or null on failure.
Pointer<TfLiteModel> Function(Pointer<Void> data, int size)
    tfLiteModelCreateFromBuffer = tflitelib
        .lookup<NativeFunction<_TfLiteModelCreateFromBuffer_native_t>>(
            'TfLiteModelCreate')
        .asFunction();

typedef _TfLiteModelCreateFromBuffer_native_t = Pointer<TfLiteModel> Function(
    Pointer<Void> data, Int32 size);

/// Returns a model from the provided file, or null on failure.
Pointer<TfLiteModel> Function(Pointer<Utf8> path) tfLiteModelCreateFromFile =
    tflitelib
        .lookup<NativeFunction<_TfLiteModelCreateFromFile_native_t>>(
            'TfLiteModelCreateFromFile')
        .asFunction();

typedef _TfLiteModelCreateFromFile_native_t = Pointer<TfLiteModel> Function(
    Pointer<Utf8> path);

/// Destroys the model instance.
void Function(Pointer<TfLiteModel>) tfLiteModelDelete = tflitelib
    .lookup<NativeFunction<_TfLiteModelDelete_native_t>>('TfLiteModelDelete')
    .asFunction();

typedef _TfLiteModelDelete_native_t = Void Function(Pointer<TfLiteModel>);
