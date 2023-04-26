
import 'dart:ffi';

import '../dlib.dart';

import '../types.dart';

// XNNPack Delegate bindings

// Creates a new delegate instance that need to be destroyed with
// `TfLiteXNNPackDelegateDelete` when delegate is no longer used by TFLite.
// When `options` is set to `nullptr`, the following default values are used:
Pointer<TfLiteDelegate> Function(Pointer<TfLiteXNNPackDelegateOptions> options)
    tfliteXNNPackDelegateCreate = tflitelib
        .lookup<NativeFunction<_TfLiteXNNPackDelegateCreate_native_t>>(
            'TfLiteXNNPackDelegateCreate')
        .asFunction();

typedef _TfLiteXNNPackDelegateCreate_native_t = Pointer<TfLiteDelegate> Function(
    Pointer<TfLiteXNNPackDelegateOptions> options);

// Destroys a delegate created with `TfLiteXNNPackDelegateCreate` call.
void Function(Pointer<TfLiteDelegate>) tfliteXNNPackDelegateDelete = tflitelib
    .lookup<NativeFunction<_TfLiteXNNPackDelegateDelete_native_t>>(
        'TfLiteXNNPackDelegateDelete')
    .asFunction();

typedef _TfLiteXNNPackDelegateDelete_native_t = Void Function(
    Pointer<TfLiteDelegate> delegate);

/// Default Options
TfLiteXNNPackDelegateOptions Function() tfLiteXNNPackDelegateOptionsDefault = tflitelib
    .lookup<NativeFunction<_TfLiteXNNPackDelegateOptions_native_t>>(
        'TfLiteXNNPackDelegateOptionsDefault')
    .asFunction();

typedef _TfLiteXNNPackDelegateOptions_native_t = TfLiteXNNPackDelegateOptions Function();
