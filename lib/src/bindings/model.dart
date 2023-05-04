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
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'dlib.dart';
import 'types.dart';

/// Returns a model from the provided buffer, or null on failure.
Pointer<TfLiteModel> Function(Pointer<Void> data, int size)
    tfLiteModelCreateFromBuffer = tflitelib
        .lookup<NativeFunction<_TfLiteModelCreateFromBufferNativeT>>(
            'TfLiteModelCreate')
        .asFunction();

typedef _TfLiteModelCreateFromBufferNativeT = Pointer<TfLiteModel> Function(
    Pointer<Void> data, Int32 size);

/// Returns a model from the provided file, or null on failure.
Pointer<TfLiteModel> Function(Pointer<Utf8> path) tfLiteModelCreateFromFile =
    tflitelib
        .lookup<NativeFunction<_TfLiteModelCreateFromFileNativeT>>(
            'TfLiteModelCreateFromFile')
        .asFunction();

typedef _TfLiteModelCreateFromFileNativeT = Pointer<TfLiteModel> Function(
    Pointer<Utf8> path);

/// Destroys the model instance.
void Function(Pointer<TfLiteModel>) tfLiteModelDelete = tflitelib
    .lookup<NativeFunction<_TfLiteModelDeleteNativeT>>('TfLiteModelDelete')
    .asFunction();

typedef _TfLiteModelDeleteNativeT = Void Function(Pointer<TfLiteModel>);
