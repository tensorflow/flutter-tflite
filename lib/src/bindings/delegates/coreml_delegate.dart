
import 'dart:ffi';

import '../dlib.dart';

import '../types.dart';

// CoreMl Delegate bindings

// Return a delegate that uses CoreML for ops execution.
// Must outlive the interpreter.
Pointer<TfLiteDelegate> Function(Pointer<TfLiteCoreMlDelegateOptions> options)
    tfliteCoreMlDelegateCreate = tflitelib
        .lookup<NativeFunction<_TfLiteCoreMlDelegateCreate_native_t>>(
            'TfLiteCoreMlDelegateCreate')
        .asFunction();

typedef _TfLiteCoreMlDelegateCreate_native_t = Pointer<TfLiteDelegate> Function(
    Pointer<TfLiteCoreMlDelegateOptions> options);

// Do any needed cleanup and delete 'delegate'.
void Function(Pointer<TfLiteDelegate>) tfliteCoreMlDelegateDelete = tflitelib
    .lookup<NativeFunction<_TfLiteCoreMlDelegateDelete_native_t>>(
        'TfLiteCoreMlDelegateDelete')
    .asFunction();

typedef _TfLiteCoreMlDelegateDelete_native_t = Void Function(
    Pointer<TfLiteDelegate> delegate);
