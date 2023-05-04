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

// Android GPU delegate bindings

/// Creates a new delegate instance that need to be destroyed with
/// TfLiteGpuDelegateV2Delete when delegate is no longer used by TFLite.
///
/// This delegate encapsulates multiple GPU-acceleration APIs under the hood to
/// make use of the fastest available on a device.
///
/// When `options` is set to `nullptr`, then default options are used.
Pointer<TfLiteDelegate> Function(Pointer<TfLiteGpuDelegateOptionsV2> options)
    tfLiteGpuDelegateV2Create = tflitelib
        .lookup<NativeFunction<_TfLiteGpuDelegateV2CreateNativeT>>(
            'TfLiteGpuDelegateV2Create')
        .asFunction();

typedef _TfLiteGpuDelegateV2CreateNativeT = Pointer<TfLiteDelegate> Function(
    Pointer<TfLiteGpuDelegateOptionsV2> options);

/// Destroys a delegate created with `TfLiteGpuDelegateV2Create` call.
void Function(Pointer<TfLiteDelegate>) tfLiteGpuDelegateV2Delete = tflitelib
    .lookup<NativeFunction<_TFLGpuDelegateV2DeleteNativeT>>(
        'TfLiteGpuDelegateV2Delete')
    .asFunction();

typedef _TFLGpuDelegateV2DeleteNativeT = Void Function(
    Pointer<TfLiteDelegate> delegate);

/// Creates TfLiteGpuDelegateV2 with default options
TfLiteGpuDelegateOptionsV2 Function() tfLiteGpuDelegateOptionsV2Default =
    tflitelib
        .lookup<
                NativeFunction<
                    _TfLiteTfLiteGpuDelegateOptionsV2DefaultNativeT>>(
            'TfLiteGpuDelegateOptionsV2Default')
        .asFunction();

typedef _TfLiteTfLiteGpuDelegateOptionsV2DefaultNativeT
    = TfLiteGpuDelegateOptionsV2 Function();
