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

/// Returns the type of a tensor element.
TfLiteType tfLiteTensorType(Pointer<TfLiteTensor> t) =>
    TfLiteType.values[_tfLiteTensorType(t)];
int Function(Pointer<TfLiteTensor>) _tfLiteTensorType = tflitelib
    .lookup<NativeFunction<_TfLiteTensorTypeNativeT>>('TfLiteTensorType')
    .asFunction();

typedef _TfLiteTensorTypeNativeT = /*TfLiteType*/ Int32 Function(
    Pointer<TfLiteTensor>);

/// Returns the number of dimensions that the tensor has.
int Function(Pointer<TfLiteTensor>) tfLiteTensorNumDims = tflitelib
    .lookup<NativeFunction<_TfLiteTensorNumDimsNativeT>>('TfLiteTensorNumDims')
    .asFunction();

typedef _TfLiteTensorNumDimsNativeT = Int32 Function(Pointer<TfLiteTensor>);

/// Returns the length of the tensor in the 'dim_index' dimension.
///
/// REQUIRES: 0 <= dim_index < TFLiteTensorNumDims(tensor)
int Function(Pointer<TfLiteTensor> tensor, int dimIndex) tfLiteTensorDim =
    tflitelib
        .lookup<NativeFunction<_TfLiteTensorDimNativeT>>('TfLiteTensorDim')
        .asFunction();

typedef _TfLiteTensorDimNativeT = Int32 Function(
    Pointer<TfLiteTensor> tensor, Int32 dimIndex);

/// Returns the size of the underlying data in bytes.
int Function(Pointer<TfLiteTensor>) tfLiteTensorByteSize = tflitelib
    .lookup<NativeFunction<_TfLiteTensorByteSizeNativeT>>(
        'TfLiteTensorByteSize')
    .asFunction();

typedef _TfLiteTensorByteSizeNativeT = Int32 Function(Pointer<TfLiteTensor>);

/// Returns a pointer to the underlying data buffer.
///
/// NOTE: The result may be null if tensors have not yet been allocated, e.g.,
/// if the Tensor has just been created or resized and `TfLiteAllocateTensors()`
/// has yet to be called, or if the output tensor is dynamically sized and the
/// interpreter hasn't been invoked.
Pointer<Void> Function(Pointer<TfLiteTensor>) tfLiteTensorData = tflitelib
    .lookup<NativeFunction<_TfLiteTensorDataNativeT>>('TfLiteTensorData')
    .asFunction();

typedef _TfLiteTensorDataNativeT = Pointer<Void> Function(
    Pointer<TfLiteTensor>);

/// Returns the (null-terminated) name of the tensor.
Pointer<Utf8> Function(Pointer<TfLiteTensor>) tfLiteTensorName = tflitelib
    .lookup<NativeFunction<_TfLiteTensorNameNativeT>>('TfLiteTensorName')
    .asFunction();

typedef _TfLiteTensorNameNativeT = Pointer<Utf8> Function(
    Pointer<TfLiteTensor>);

/// Copies from the provided input buffer into the tensor's buffer.
///
/// REQUIRES: input_data_size == TfLiteTensorByteSize(tensor)
/*TfLiteStatus*/
int Function(
  Pointer<TfLiteTensor> tensor,
  Pointer<Void> inputData,
  int inputDataSize,
) tfLiteTensorCopyFromBuffer = tflitelib
    .lookup<NativeFunction<_TfLiteTensorCopyFromBufferNativeT>>(
        'TfLiteTensorCopyFromBuffer')
    .asFunction();

typedef _TfLiteTensorCopyFromBufferNativeT = /*TfLiteStatus*/ Int32 Function(
  Pointer<TfLiteTensor> tensor,
  Pointer<Void> inputData,
  Int32 inputDataSize,
);

/// Copies to the provided output buffer from the tensor's buffer.
///
/// REQUIRES: output_data_size == TfLiteTensorByteSize(tensor)
/*TfLiteStatus*/
int Function(
  Pointer<TfLiteTensor> tensor,
  Pointer<Void> outputData,
  int outputDataSize,
) tfLiteTensorCopyToBuffer = tflitelib
    .lookup<NativeFunction<_TfLiteTensorCopyToBufferNativeT>>(
        'TfLiteTensorCopyToBuffer')
    .asFunction();

typedef _TfLiteTensorCopyToBufferNativeT = /*TfLiteStatus*/ Int32 Function(
  Pointer<TfLiteTensor> tensor,
  Pointer<Void> outputData,
  Int32 outputDataSize,
);

TfLiteQuantizationParams Function(Pointer<TfLiteTensor> tensor)
    tfLiteTensorQuantizationParams = tflitelib
        .lookup<NativeFunction<_TfLiteTensorQuantizationParamsNativeT>>(
            'TfLiteTensorQuantizationParams')
        .asFunction();

typedef _TfLiteTensorQuantizationParamsNativeT = TfLiteQuantizationParams
    Function(Pointer<TfLiteTensor> tensor);
