import 'dart:ffi';

import 'dlib.dart';
import 'types.dart';

/// Returns a new interpreter using the provided model and options, or null on
/// failure.
///
/// * `model` must be a valid model instance. The caller retains ownership of the
///   object, and can destroy it immediately after creating the interpreter; the
///   interpreter will maintain its own reference to the underlying model data.
/// * `optional_options` may be null. The caller retains ownership of the object,
///   and can safely destroy it immediately after creating the interpreter.
//
/// NOTE: The client *must* explicitly allocate tensors before attempting to
/// access input tensor data or invoke the interpreter.
Pointer<TfLiteInterpreter> Function(Pointer<TfLiteModel> model,
        Pointer<TfLiteInterpreterOptions> optionalOptions)
    tfLiteInterpreterCreate = tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterCreate_native_t>>(
            'TfLiteInterpreterCreate')
        .asFunction();

typedef _TfLiteInterpreterCreate_native_t = Pointer<TfLiteInterpreter> Function(
    Pointer<TfLiteModel> model,
    Pointer<TfLiteInterpreterOptions> optionalOptions);

/// Destroys the interpreter.
void Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterDelete = tflitelib
    .lookup<NativeFunction<_TfLiteInterpreterDelete_native_t>>(
        'TfLiteInterpreterDelete')
    .asFunction();

typedef _TfLiteInterpreterDelete_native_t = Void Function(
    Pointer<TfLiteInterpreter>);

/// Returns the number of input tensors associated with the model.
int Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterGetInputTensorCount =
    tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterGetInputTensorCount_native_t>>(
            'TfLiteInterpreterGetInputTensorCount')
        .asFunction();

typedef _TfLiteInterpreterGetInputTensorCount_native_t = Int32 Function(
    Pointer<TfLiteInterpreter>);

/// Returns the tensor associated with the input index.
///
/// REQUIRES: 0 <= input_index < TfLiteInterpreterGetInputTensorCount(tensor)
Pointer<TfLiteTensor> Function(
        Pointer<TfLiteInterpreter> interpreter, int inputIndex)
    tfLiteInterpreterGetInputTensor = tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterGetInputTensor_native_t>>(
            'TfLiteInterpreterGetInputTensor')
        .asFunction();

typedef _TfLiteInterpreterGetInputTensor_native_t = Pointer<TfLiteTensor>
    Function(Pointer<TfLiteInterpreter> interpreter, Int32 inputIndex);

/// Resizes the specified input tensor.
///
/// NOTE: After a resize, the client *must* explicitly allocate tensors before
/// attempting to access the resized tensor data or invoke the interpreter.
/// REQUIRES: 0 <= input_index < TfLiteInterpreterGetInputTensorCount(tensor)
/*TfLiteStatus*/
int Function(Pointer<TfLiteInterpreter> interpreter, int inputIndex,
        Pointer<Int32> inputDims, int inputDimsSize)
    tfLiteInterpreterResizeInputTensor = tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterResizeInputTensor_native_t>>(
            'TfLiteInterpreterResizeInputTensor')
        .asFunction();

typedef _TfLiteInterpreterResizeInputTensor_native_t
    = /*TfLiteStatus*/ Int32 Function(Pointer<TfLiteInterpreter> interpreter,
        Int32 inputIndex, Pointer<Int32> inputDims, Int32 inputDimsSize);

/// Updates allocations for all tensors, resizing dependent tensors using the
/// specified input tensor dimensionality.
///
/// This is a relatively expensive operation, and need only be called after
/// creating the graph and/or resizing any inputs.
/*TfLiteStatus*/
int Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterAllocateTensors =
    tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterAllocateTensors_native_t>>(
            'TfLiteInterpreterAllocateTensors')
        .asFunction();

typedef _TfLiteInterpreterAllocateTensors_native_t = /*TfLiteStatus*/ Int32
    Function(Pointer<TfLiteInterpreter>);

/// Runs inference for the loaded graph.
///
/// NOTE: It is possible that the interpreter is not in a ready state to
/// evaluate (e.g., if a ResizeInputTensor() has been performed without a call to
/// AllocateTensors()).
/*TfLiteStatus*/
int Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterInvoke = tflitelib
    .lookup<NativeFunction<_TfLiteInterpreterInvoke_native_t>>(
        'TfLiteInterpreterInvoke')
    .asFunction();

typedef _TfLiteInterpreterInvoke_native_t = /*TfLiteStatus*/ Int32 Function(
    Pointer<TfLiteInterpreter>);

/// Returns the number of output tensors associated with the model.
int Function(
    Pointer<
        TfLiteInterpreter>) tfLiteInterpreterGetOutputTensorCount = tflitelib
    .lookup<NativeFunction<_TfLiteInterpreterGetOutputTensorCount_native_t>>(
        'TfLiteInterpreterGetOutputTensorCount')
    .asFunction();

typedef _TfLiteInterpreterGetOutputTensorCount_native_t = Int32 Function(
    Pointer<TfLiteInterpreter>);

/// Returns the tensor associated with the output index.
///
/// REQUIRES: 0 <= input_index < TfLiteInterpreterGetOutputTensorCount(tensor)
///
/// NOTE: The shape and underlying data buffer for output tensors may be not
/// be available until after the output tensor has been both sized and allocated.
/// In general, best practice is to interact with the output tensor *after*
/// calling TfLiteInterpreterInvoke().
Pointer<TfLiteTensor> Function(
        Pointer<TfLiteInterpreter> interpreter, int outputIndex)
    tfLiteInterpreterGetOutputTensor = tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterGetOutputTensor_native_t>>(
            'TfLiteInterpreterGetOutputTensor')
        .asFunction();

typedef _TfLiteInterpreterGetOutputTensor_native_t = Pointer<TfLiteTensor>
    Function(Pointer<TfLiteInterpreter> interpreter, Int32 outputIndex);
