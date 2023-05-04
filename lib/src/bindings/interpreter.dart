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
        .lookup<NativeFunction<_TfLiteInterpreterCreateNativeT>>(
            'TfLiteInterpreterCreate')
        .asFunction();

typedef _TfLiteInterpreterCreateNativeT = Pointer<TfLiteInterpreter> Function(
    Pointer<TfLiteModel> model,
    Pointer<TfLiteInterpreterOptions> optionalOptions);

/// Destroys the interpreter.
void Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterDelete = tflitelib
    .lookup<NativeFunction<_TfLiteInterpreterDeleteNativeT>>(
        'TfLiteInterpreterDelete')
    .asFunction();

typedef _TfLiteInterpreterDeleteNativeT = Void Function(
    Pointer<TfLiteInterpreter>);

/// Returns the number of input tensors associated with the model.
int Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterGetInputTensorCount =
    tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterGetInputTensorCountNativeT>>(
            'TfLiteInterpreterGetInputTensorCount')
        .asFunction();

typedef _TfLiteInterpreterGetInputTensorCountNativeT = Int32 Function(
    Pointer<TfLiteInterpreter>);

/// Returns the tensor associated with the input index.
///
/// REQUIRES: 0 <= input_index < TfLiteInterpreterGetInputTensorCount(tensor)
Pointer<TfLiteTensor> Function(
        Pointer<TfLiteInterpreter> interpreter, int inputIndex)
    tfLiteInterpreterGetInputTensor = tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterGetInputTensorNativeT>>(
            'TfLiteInterpreterGetInputTensor')
        .asFunction();

typedef _TfLiteInterpreterGetInputTensorNativeT = Pointer<TfLiteTensor>
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
        .lookup<NativeFunction<_TfLiteInterpreterResizeInputTensorNativeT>>(
            'TfLiteInterpreterResizeInputTensor')
        .asFunction();

typedef _TfLiteInterpreterResizeInputTensorNativeT
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
        .lookup<NativeFunction<_TfLiteInterpreterAllocateTensorsNativeT>>(
            'TfLiteInterpreterAllocateTensors')
        .asFunction();

typedef _TfLiteInterpreterAllocateTensorsNativeT = /*TfLiteStatus*/ Int32
    Function(Pointer<TfLiteInterpreter>);

/// Runs inference for the loaded graph.
///
/// NOTE: It is possible that the interpreter is not in a ready state to
/// evaluate (e.g., if a ResizeInputTensor() has been performed without a call to
/// AllocateTensors()).
/*TfLiteStatus*/
int Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterInvoke = tflitelib
    .lookup<NativeFunction<_TfLiteInterpreterInvokeNativeT>>(
        'TfLiteInterpreterInvoke')
    .asFunction();

typedef _TfLiteInterpreterInvokeNativeT = /*TfLiteStatus*/ Int32 Function(
    Pointer<TfLiteInterpreter>);

/// Returns the number of output tensors associated with the model.
int Function(Pointer<TfLiteInterpreter>) tfLiteInterpreterGetOutputTensorCount =
    tflitelib
        .lookup<NativeFunction<_TfLiteInterpreterGetOutputTensorCountNativeT>>(
            'TfLiteInterpreterGetOutputTensorCount')
        .asFunction();

typedef _TfLiteInterpreterGetOutputTensorCountNativeT = Int32 Function(
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
        .lookup<NativeFunction<_TfLiteInterpreterGetOutputTensorNativeT>>(
            'TfLiteInterpreterGetOutputTensor')
        .asFunction();

typedef _TfLiteInterpreterGetOutputTensorNativeT = Pointer<TfLiteTensor>
    Function(Pointer<TfLiteInterpreter> interpreter, Int32 outputIndex);
