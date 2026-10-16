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
import 'package:tflite_core/src/bindings/bindings.dart';
import 'package:tflite_core/src/bindings/tensorflow_lite_bindings_generated.dart';
import 'package:tflite_core/src/util/byte_conversion_utils.dart';
import 'package:flutter/foundation.dart';

import 'ffi/helper.dart';
import 'quanitzation_params.dart';
import 'util/list_shape_extension.dart';

export 'bindings/tensorflow_lite_bindings_generated.dart' show TfLiteType;

/// A TensorFlow Lite input or output tensor.
class Tensor {
  final Pointer<TfLiteTensor> _tensor;

  /// Wraps the native tensor pointer owned by an [Interpreter].
  Tensor(this._tensor) {
    ArgumentError.checkNotNull(_tensor);
  }

  /// Name of the tensor element.
  String get name => tfliteBinding.TfLiteTensorName(_tensor).cast<Utf8>().toDartString();

  /// Data type of the tensor element.
  TensorType get type => TensorType.fromValue(
        tfliteBinding.TfLiteTensorType(_tensor),
      );

  /// Dimensions of the tensor.
  List<int> get shape => List.generate(
      tfliteBinding.TfLiteTensorNumDims(_tensor), (i) => tfliteBinding.TfLiteTensorDim(_tensor, i));

  /// Underlying data buffer as bytes.
  Uint8List get data {
    final data = cast<Uint8>(tfliteBinding.TfLiteTensorData(_tensor));
    return data.asTypedList(tfliteBinding.TfLiteTensorByteSize(_tensor)).asUnmodifiableView();
  }

  /// Quantization parameters associated with this tensor.
  QuantizationParams get params {
    final ref = tfliteBinding.TfLiteTensorQuantizationParams(_tensor);
    return QuantizationParams(ref.scale, ref.zero_point);
  }

  /// Updates the underlying data buffer with new bytes.
  ///
  /// The size must match the size of the tensor.
  set data(Uint8List bytes) {
    final tensorByteSize = tfliteBinding.TfLiteTensorByteSize(_tensor);
    checkArgument(tensorByteSize == bytes.length);
    final data = cast<Uint8>(tfliteBinding.TfLiteTensorData(_tensor));
    checkState(isNotNull(data), message: 'Tensor data is null.');
    final externalTypedData = data.asTypedList(tensorByteSize);
    externalTypedData.setRange(0, tensorByteSize, bytes);
  }

  /// Returns the number of dimensions in this tensor's shape.
  int numDimensions() {
    return tfliteBinding.TfLiteTensorNumDims(_tensor);
  }

  /// Returns the size of the tensor data in bytes.
  int numBytes() {
    return tfliteBinding.TfLiteTensorByteSize(_tensor);
  }

  /// Returns the number of elements in this tensor.
  int numElements() {
    return computeNumElements(shape);
  }

  /// Returns the product of the dimensions in [shape].
  static int computeNumElements(List<int> shape) {
    int n = 1;
    for (var i = 0; i < shape.length; i++) {
      n *= shape[i];
    }
    return n;
  }

  /// Returns the dimensions of a nested list or other object.
  static List<int> computeShapeOf(Object o) {
    int size = computeNumDimensions(o);
    List<int> dimensions = List.filled(size, 0, growable: false);
    fillShape(o, 0, dimensions);
    return dimensions;
  }

  /// Returns the number of dimensions in a nested list, or zero for other values.
  static int computeNumDimensions(Object? o) {
    if (o == null || o is! List) {
      return 0;
    }
    if (o.isEmpty) {
      throw ArgumentError('Array lengths cannot be 0.');
    }
    return 1 + computeNumDimensions(o.elementAt(0));
  }

  /// Populates [shape] with the dimensions of the nested list [o], starting at [dim].
  static void fillShape(Object o, int dim, List<int>? shape) {
    if (shape == null || dim == shape.length) {
      return;
    }
    final len = (o as List).length;
    if (shape[dim] == 0) {
      shape[dim] = len;
    } else if (shape[dim] != len) {
      throw ArgumentError('Mismatched lengths ${shape[dim]} and $len in dimension $dim');
    }
    for (var i = 0; i < len; ++i) {
      fillShape(o.elementAt(0), dim + 1, shape);
    }
  }

  /// Returns the TensorFlow Lite data type corresponding to [o]'s leaf values.
  static int dataTypeOf(Object o) {
    while (o is List) {
      o = o.elementAt(0);
    }
    Object c = o;
    if (c is double) {
      return TfLiteType.kTfLiteFloat32;
    } else if (c is int) {
      return TfLiteType.kTfLiteInt32;
    } else if (c is String) {
      return TfLiteType.kTfLiteString;
    } else if (c is bool) {
      return TfLiteType.kTfLiteBool;
    }
    throw ArgumentError('DataType error: cannot resolve DataType of ${o.runtimeType}');
  }

  /// Copies [src] into this tensor, converting values to its data type.
  void setTo(Object src) {
    Uint8List bytes = _convertObjectToBytes(src);
    int size = bytes.length;
    final ptr = calloc<Uint8>(size);
    checkState(isNotNull(ptr), message: 'unallocated');
    final externalTypedData = ptr.asTypedList(size);
    externalTypedData.setRange(0, bytes.length, bytes);
    try {
      checkState(tfliteBinding.TfLiteTensorCopyFromBuffer(_tensor, ptr.cast(), bytes.length) ==
          TfLiteStatus.kTfLiteOk);
    } catch (_) {
      rethrow;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Copies this tensor's contents into [dst] and returns the copied value.
  Object copyTo(Object dst) {
    int size = tfliteBinding.TfLiteTensorByteSize(_tensor);
    final ptr = calloc<Uint8>(size);
    checkState(isNotNull(ptr), message: 'unallocated');
    final externalTypedData = ptr.asTypedList(size);
    checkState(tfliteBinding.TfLiteTensorCopyToBuffer(_tensor, ptr.cast(), size) ==
        TfLiteStatus.kTfLiteOk);
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

  /// Returns the input shape when [input] differs from this tensor's shape.
  List<int>? getInputShapeIfDifferent(Object? input) {
    if (input == null) {
      return null;
    }
    if (input is ByteBuffer || input is Uint8List) {
      return null;
    }

    final inputShape = computeShapeOf(input);
    if (listEquals(inputShape, shape)) {
      return null;
    }

    return inputShape;
  }

  /// Returns a string containing this tensor's metadata.
  @override
  String toString() {
    return 'Tensor{_tensor: $_tensor, name: $name, type: $type, shape: $shape, data: ${data.length}}';
  }
}

/// Data types supported by TensorFlow Lite tensors.
enum TensorType {
  /// No tensor data type is set.
  noType(TfLiteType.kTfLiteNoType),

  /// 32-bit floating-point values.
  float32(TfLiteType.kTfLiteFloat32),

  /// 32-bit signed integer values.
  int32(TfLiteType.kTfLiteInt32),

  /// 8-bit unsigned integer values.
  uint8(TfLiteType.kTfLiteUInt8),

  /// 64-bit signed integer values.
  int64(TfLiteType.kTfLiteInt64),

  /// String values.
  string(TfLiteType.kTfLiteString),

  /// Boolean values.
  boolean(TfLiteType.kTfLiteBool),

  /// 16-bit signed integer values.
  int16(TfLiteType.kTfLiteInt16),

  /// 64-bit complex values.
  complex64(TfLiteType.kTfLiteComplex64),

  /// 8-bit signed integer values.
  int8(TfLiteType.kTfLiteInt8),

  /// 16-bit floating-point values.
  float16(TfLiteType.kTfLiteFloat16),

  /// 64-bit floating-point values.
  float64(TfLiteType.kTfLiteFloat64),

  /// 128-bit complex values.
  complex128(TfLiteType.kTfLiteComplex128),

  /// 64-bit unsigned integer values.
  uint64(TfLiteType.kTfLiteUInt64),

  /// Resource handle values.
  resource(TfLiteType.kTfLiteResource),

  /// Variant values.
  variant(TfLiteType.kTfLiteVariant),

  /// 32-bit unsigned integer values.
  uint32(TfLiteType.kTfLiteUInt32),

  /// 16-bit unsigned integer values.
  uint16(TfLiteType.kTfLiteUInt16),

  /// 4-bit signed integer values.
  int4(TfLiteType.kTfLiteInt4);

  /// Creates a tensor type from its TensorFlow Lite numeric value.
  const TensorType(this.value);

  /// Returns the tensor type for the native [tfLiteValue].
  ///
  /// Returns [TensorType.noType] if the value is not recognized.
  static TensorType fromValue(int tfLiteValue) {
    switch (tfLiteValue) {
      case TfLiteType.kTfLiteFloat32:
        return TensorType.float32;
      case TfLiteType.kTfLiteInt32:
        return TensorType.int32;
      case TfLiteType.kTfLiteUInt8:
        return TensorType.uint8;
      case TfLiteType.kTfLiteInt64:
        return TensorType.int64;
      case TfLiteType.kTfLiteString:
        return TensorType.string;
      case TfLiteType.kTfLiteBool:
        return TensorType.boolean;
      case TfLiteType.kTfLiteInt16:
        return TensorType.int16;
      case TfLiteType.kTfLiteComplex64:
        return TensorType.complex64;
      case TfLiteType.kTfLiteInt8:
        return TensorType.int8;
      case TfLiteType.kTfLiteFloat16:
        return TensorType.float16;
      case TfLiteType.kTfLiteFloat64:
        return TensorType.float64;
      case TfLiteType.kTfLiteComplex128:
        return TensorType.complex128;
      case TfLiteType.kTfLiteUInt64:
        return TensorType.uint64;
      case TfLiteType.kTfLiteResource:
        return TensorType.resource;
      case TfLiteType.kTfLiteVariant:
        return TensorType.variant;
      case TfLiteType.kTfLiteUInt32:
        return TensorType.uint32;
      case TfLiteType.kTfLiteUInt16:
        return TensorType.uint16;
      case TfLiteType.kTfLiteInt4:
        return TensorType.int4;
      default:
        return TensorType.noType;
    }
  }

  /// The native TensorFlow Lite type value.
  final int value;

  /// Returns the enum name.
  @override
  String toString() => name;
}
