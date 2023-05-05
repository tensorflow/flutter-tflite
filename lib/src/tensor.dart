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
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter/src/util/byte_conversion_utils.dart';

import 'bindings/tensor.dart';
import 'bindings/types.dart';
import 'ffi/helper.dart';
import 'quanitzation_params.dart';
import 'util/list_shape_extension.dart';

export 'bindings/types.dart' show TfLiteType;

/// TensorFlowLite tensor.
class Tensor {
  final Pointer<TfLiteTensor> _tensor;

  Tensor(this._tensor) {
    ArgumentError.checkNotNull(_tensor);
  }

  /// Name of the tensor element.
  String get name => tfLiteTensorName(_tensor).toDartString();

  /// Data type of the tensor element.
  TfLiteType get type => tfLiteTensorType(_tensor);

  /// Dimensions of the tensor.
  List<int> get shape => List.generate(
      tfLiteTensorNumDims(_tensor), (i) => tfLiteTensorDim(_tensor, i));

  /// Underlying data buffer as bytes.
  Uint8List get data {
    final data = cast<Uint8>(tfLiteTensorData(_tensor));
    return UnmodifiableUint8ListView(
        data.asTypedList(tfLiteTensorByteSize(_tensor)));
  }

  /// Quantization Params associated with the model, [only Android]
  QuantizationParams get params {
    final ref = tfLiteTensorQuantizationParams(_tensor);
    return QuantizationParams(ref.scale, ref.zeroPoint);
  }

  /// Updates the underlying data buffer with new bytes.
  ///
  /// The size must match the size of the tensor.
  set data(Uint8List bytes) {
    final tensorByteSize = tfLiteTensorByteSize(_tensor);
    checkArgument(tensorByteSize == bytes.length);
    final data = cast<Uint8>(tfLiteTensorData(_tensor));
    checkState(isNotNull(data), message: 'Tensor data is null.');
    final externalTypedData = data.asTypedList(tensorByteSize);
    externalTypedData.setRange(0, tensorByteSize, bytes);
  }

  /// Returns number of dimensions
  int numDimensions() {
    return tfLiteTensorNumDims(_tensor);
  }

  /// Returns the size, in bytes, of the tensor data.
  int numBytes() {
    return tfLiteTensorByteSize(_tensor);
  }

  /// Returns the number of elements in a flattened (1-D) view of the tensor.
  int numElements() {
    return computeNumElements(shape);
  }

  /// Returns the number of elements in a flattened (1-D) view of the tensor's shape.
  static int computeNumElements(List<int> shape) {
    int n = 1;
    for (var i = 0; i < shape.length; i++) {
      n *= shape[i];
    }
    return n;
  }

  /// Returns shape of an object as an int list
  static List<int> computeShapeOf(Object o) {
    int size = computeNumDimensions(o);
    List<int> dimensions = List.filled(size, 0, growable: false);
    fillShape(o, 0, dimensions);
    return dimensions;
  }

  /// Returns the number of dimensions of a multi-dimensional array, otherwise 0.
  static int computeNumDimensions(Object? o) {
    if (o == null || o is! List) {
      return 0;
    }
    if (o.isEmpty) {
      throw ArgumentError('Array lengths cannot be 0.');
    }
    return 1 + computeNumDimensions(o.elementAt(0));
  }

  /// Recursively populates the shape dimensions for a given (multi-dimensional) array)
  static void fillShape(Object o, int dim, List<int>? shape) {
    if (shape == null || dim == shape.length) {
      return;
    }
    final len = (o as List).length;
    if (shape[dim] == 0) {
      shape[dim] = len;
    } else if (shape[dim] != len) {
      throw ArgumentError(
          'Mismatched lengths ${shape[dim]} and $len in dimension $dim');
    }
    for (var i = 0; i < len; ++i) {
      fillShape(o.elementAt(0), dim + 1, shape);
    }
  }

  /// Returns data type of given object
  static TfLiteType dataTypeOf(Object o) {
    while (o is List) {
      o = o.elementAt(0);
    }
    Object c = o;
    if (c is double) {
      return TfLiteType.float32;
    } else if (c is int) {
      return TfLiteType.int32;
    } else if (c is String) {
      return TfLiteType.string;
    } else if (c is bool) {
      return TfLiteType.bool;
    }
    throw ArgumentError(
        'DataType error: cannot resolve DataType of ${o.runtimeType}');
  }

  void setTo(Object src) {
    Uint8List bytes = _convertObjectToBytes(src);
    int size = bytes.length;
    final ptr = calloc<Uint8>(size);
    checkState(isNotNull(ptr), message: 'unallocated');
    final externalTypedData = ptr.asTypedList(size);
    externalTypedData.setRange(0, bytes.length, bytes);
    try {
      checkState(
          tfLiteTensorCopyFromBuffer(_tensor, ptr.cast(), bytes.length) ==
              TfLiteStatus.ok);
    } catch (_) {
      rethrow;
    } finally {
      calloc.free(ptr);
    }
  }

  Object copyTo(Object dst) {
    int size = tfLiteTensorByteSize(_tensor);
    final ptr = calloc<Uint8>(size);
    checkState(isNotNull(ptr), message: 'unallocated');
    final externalTypedData = ptr.asTypedList(size);
    checkState(
        tfLiteTensorCopyToBuffer(_tensor, ptr.cast(), size) == TfLiteStatus.ok);
    // Clone the data, because once `free(ptr)`, `externalTypedData` will be
    // volatile
    final bytes = externalTypedData.sublist(0);
    data = bytes;
    late Object obj;
    if (dst is Uint8List) {
      obj = bytes;
    } else if (dst is ByteBuffer) {
      ByteData bdata = dst.asByteData();
      for (int i = 0; i < bdata.lengthInBytes; i++) {
        bdata.setUint8(i, bytes[i]);
      }
      obj = bdata.buffer;
    } else {
      obj = _convertBytesToObject(bytes);
    }
    calloc.free(ptr);
    if (obj is List && dst is List) {
      _duplicateList(obj, dst);
    } else {
      dst = obj;
    }
    return obj;
  }

  Uint8List _convertObjectToBytes(Object o) {
    return ByteConversionUtils.convertObjectToBytes(o, type);
  }

  Object _convertBytesToObject(Uint8List bytes) {
    return ByteConversionUtils.convertBytesToObject(bytes, type, shape);
  }

  void _duplicateList(List obj, List dst) {
    var objShape = obj.shape;
    var dstShape = dst.shape;
    var equal = true;
    if (objShape.length == dst.shape.length) {
      for (var i = 0; i < objShape.length; i++) {
        if (objShape[i] != dstShape[i]) {
          equal = false;
          break;
        }
      }
    } else {
      equal = false;
    }
    if (equal == false) {
      throw ArgumentError(
          'Output object shape mismatch, interpreter returned output of shape: ${obj.shape} while shape of output provided as argument in run is: ${dst.shape}');
    }
    for (var i = 0; i < obj.length; i++) {
      dst[i] = obj[i];
    }
  }

  List<int>? getInputShapeIfDifferent(Object? input) {
    if (input == null) {
      return null;
    }
    if (input is ByteBuffer || input is Uint8List) {
      return null;
    }

    final inputShape = computeShapeOf(input);
    if (inputShape == shape) {
      return null;
    }
    return inputShape;
  }

  @override
  String toString() {
    return 'Tensor{_tensor: $_tensor, name: $name, type: $type, shape: $shape, data: ${data.length}}';
  }
}
