/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// iOS metal delegate

import 'dart:ffi';

import '../dlib.dart';

import '../types.dart';

// iOS metal delegate bindings

/// Creates a new delegate instance that need to be destroyed with
/// `TFLDeleteTfLiteGpuDelegate` when delegate is no longer used by TFLite.
/// When `options` is set to `nullptr`, the following default values are used:
/// .precision_loss_allowed = false,
/// .wait_type = kPassive,
Pointer<TfLiteDelegate> Function(Pointer<TFLGpuDelegateOptions>? options)
    tflGpuDelegateCreate = tflitelib
        .lookup<NativeFunction<_TFLGpuDelegateCreateNativeT>>(
            'TFLGpuDelegateCreate')
        .asFunction();

typedef _TFLGpuDelegateCreateNativeT = Pointer<TfLiteDelegate> Function(
    Pointer<TFLGpuDelegateOptions>? options);

/// Destroys a delegate created with `TFLGpuDelegateCreate` call.
void Function(Pointer<TfLiteDelegate>) tflGpuDelegateDelete = tflitelib
    .lookup<NativeFunction<_TFLGpuDelegateDeleteNativeT>>(
        'TFLGpuDelegateDelete')
    .asFunction();

typedef _TFLGpuDelegateDeleteNativeT = Void Function(
    Pointer<TfLiteDelegate> delegate);

/// Default Options
TFLGpuDelegateOptions Function() tflGpuDelegateOptionsDefault = tflitelib
    .lookup<NativeFunction<_TFLGpuDelegateOptionsNativeT>>(
        'TFLGpuDelegateOptionsDefault')
    .asFunction();

typedef _TFLGpuDelegateOptionsNativeT = TFLGpuDelegateOptions Function();
