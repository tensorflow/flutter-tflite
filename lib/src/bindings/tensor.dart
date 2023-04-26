import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'dlib.dart';
import 'types.dart';

/// Returns the type of a tensor element.
TfLiteType tfLiteTensorType(Pointer<TfLiteTensor> t) =>
    TfLiteType.values[_tfLiteTensorType(t)];
int Function(Pointer<TfLiteTensor>) _tfLiteTensorType = tflitelib
    .lookup<NativeFunction<_TfLiteTensorType_native_t>>('TfLiteTensorType')
    .asFunction();

typedef _TfLiteTensorType_native_t = /*TfLiteType*/ Int32 Function(
    Pointer<TfLiteTensor>);

/// Returns the number of dimensions that the tensor has.
int Function(Pointer<TfLiteTensor>) tfLiteTensorNumDims = tflitelib
    .lookup<NativeFunction<_TfLiteTensorNumDims_native_t>>(
        'TfLiteTensorNumDims')
    .asFunction();

typedef _TfLiteTensorNumDims_native_t = Int32 Function(Pointer<TfLiteTensor>);

/// Returns the length of the tensor in the 'dim_index' dimension.
///
/// REQUIRES: 0 <= dim_index < TFLiteTensorNumDims(tensor)
int Function(Pointer<TfLiteTensor> tensor, int dimIndex) tfLiteTensorDim =
    tflitelib
        .lookup<NativeFunction<_TfLiteTensorDim_native_t>>('TfLiteTensorDim')
        .asFunction();

typedef _TfLiteTensorDim_native_t = Int32 Function(
    Pointer<TfLiteTensor> tensor, Int32 dimIndex);

/// Returns the size of the underlying data in bytes.
int Function(Pointer<TfLiteTensor>) tfLiteTensorByteSize = tflitelib
    .lookup<NativeFunction<_TfLiteTensorByteSize_native_t>>(
        'TfLiteTensorByteSize')
    .asFunction();

typedef _TfLiteTensorByteSize_native_t = Int32 Function(Pointer<TfLiteTensor>);

/// Returns a pointer to the underlying data buffer.
///
/// NOTE: The result may be null if tensors have not yet been allocated, e.g.,
/// if the Tensor has just been created or resized and `TfLiteAllocateTensors()`
/// has yet to be called, or if the output tensor is dynamically sized and the
/// interpreter hasn't been invoked.
Pointer<Void> Function(Pointer<TfLiteTensor>) tfLiteTensorData = tflitelib
    .lookup<NativeFunction<_TfLiteTensorData_native_t>>('TfLiteTensorData')
    .asFunction();

typedef _TfLiteTensorData_native_t = Pointer<Void> Function(
    Pointer<TfLiteTensor>);

/// Returns the (null-terminated) name of the tensor.
Pointer<Utf8> Function(Pointer<TfLiteTensor>) tfLiteTensorName = tflitelib
    .lookup<NativeFunction<_TfLiteTensorName_native_t>>('TfLiteTensorName')
    .asFunction();

typedef _TfLiteTensorName_native_t = Pointer<Utf8> Function(
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
    .lookup<NativeFunction<_TfLiteTensorCopyFromBuffer_native_t>>(
        'TfLiteTensorCopyFromBuffer')
    .asFunction();

typedef _TfLiteTensorCopyFromBuffer_native_t = /*TfLiteStatus*/ Int32 Function(
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
    .lookup<NativeFunction<_TfLiteTensorCopyToBuffer_native_t>>(
        'TfLiteTensorCopyToBuffer')
    .asFunction();

typedef _TfLiteTensorCopyToBuffer_native_t = /*TfLiteStatus*/ Int32 Function(
  Pointer<TfLiteTensor> tensor,
  Pointer<Void> outputData,
  Int32 outputDataSize,
);

TfLiteQuantizationParams Function(Pointer<TfLiteTensor> tensor)
    tfLiteTensorQuantizationParams = tflitelib
        .lookup<NativeFunction<_TfLiteTensorQuantizationParams_native_t>>(
            'TfLiteTensorQuantizationParams')
        .asFunction();

typedef _TfLiteTensorQuantizationParams_native_t
    = TfLiteQuantizationParams Function(Pointer<TfLiteTensor> tensor);
