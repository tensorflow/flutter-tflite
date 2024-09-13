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

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

class ByteConversionError extends ArgumentError {
  ByteConversionError({
    required this.input,
    required this.tensorType,
  }) : super(
          'The input element is ${input.runtimeType} while tensor data type is $tensorType',
        );

  final Object input;
  final TensorType tensorType;
}

class ByteConversionUtils {
  static Uint8List convertObjectToBytes(Object o, TensorType tensorType) {
    if (o is Uint8List) {
      return o;
    }
    if (o is ByteBuffer) {
      return o.asUint8List();
    }
    List<int> bytes = <int>[];
    if (o is List) {
      for (var e in o) {
        bytes.addAll(convertObjectToBytes(e, tensorType));
      }
    } else {
      return _convertElementToBytes(o, tensorType);
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List _convertElementToBytes(Object o, TensorType tensorType) {
    // Float32
    if (tensorType.value == TfLiteType.kTfLiteFloat32) {
      if (o is num) {
        var buffer = Uint8List(4).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setFloat32(0, o.toDouble(), Endian.little);
        return buffer.asUint8List();
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    // Uint8
    if (tensorType.value == TfLiteType.kTfLiteUInt8) {
      if (o is int) {
        var buffer = Uint8List(1).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setUint8(0, o);
        return buffer.asUint8List();
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    // Int32
    if (tensorType.value == TfLiteType.kTfLiteInt32) {
      if (o is int) {
        var buffer = Uint8List(4).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt32(0, o, Endian.little);
        return buffer.asUint8List();
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    // Int64
    if (tensorType.value == TfLiteType.kTfLiteInt64) {
      if (o is int) {
        var buffer = Uint8List(8).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt64(0, o, Endian.big);
        return buffer.asUint8List();
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    // Int16
    if (tensorType.value == TfLiteType.kTfLiteInt16) {
      if (o is int) {
        var buffer = Uint8List(2).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt16(0, o, Endian.little);
        return buffer.asUint8List();
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    // Float16
    if (tensorType.value == TfLiteType.kTfLiteFloat16) {
      if (o is num) {
        return ByteConversionUtils.floatToFloat16Bytes(o.toDouble());
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    // Int8
    if (tensorType.value == TfLiteType.kTfLiteInt8) {
      if (o is int) {
        var buffer = Uint8List(1).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt8(0, o);
        return buffer.asUint8List();
      }
      throw ByteConversionError(
        input: o,
        tensorType: tensorType,
      );
    }

    throw ArgumentError(
      'The input data tfliteType ${o.runtimeType} is unsupported',
    );
  }

  /// Decodes a TensorFlow string to a List<String>
  static List<String> decodeTFStrings(Uint8List bytes) {
    /// The decoded string
    List<String> decodedStrings = [];

    /// get the first 32bit int representing num of strings
    int numStrings = ByteData.view(bytes.sublist(0, sizeOf<Int32>()).buffer)
        .getInt32(0, Endian.little);

    /// parse subsequent string position and sizes
    for (int s = 0; s < numStrings; s++) {
      // get current str index
      int startIdx = ByteData.view(bytes
              .sublist((1 + s) * sizeOf<Int32>(), (2 + s) * sizeOf<Int32>())
              .buffer)
          .getInt32(0, Endian.little);
      // get next str index, or in last case the ending byte position
      int endIdx = ByteData.view(bytes
              .sublist((2 + s) * sizeOf<Int32>(), (3 + s) * sizeOf<Int32>())
              .buffer)
          .getInt32(0, Endian.little);

      decodedStrings.add(utf8.decode(bytes.sublist(startIdx, endIdx)));
    }

    return decodedStrings;
  }

  static Object convertBytesToObject(
      Uint8List bytes, TensorType tensorType, List<int> shape) {
    // stores flattened data
    List<dynamic> list = [];
    if (tensorType.value == TfLiteType.kTfLiteInt32) {
      for (var i = 0; i < bytes.length; i += 4) {
        list.add(ByteData.view(bytes.buffer).getInt32(i, Endian.little));
      }
      return list.reshape<int>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteFloat32) {
      for (var i = 0; i < bytes.length; i += 4) {
        list.add(ByteData.view(bytes.buffer).getFloat32(i, Endian.little));
      }
      return list.reshape<double>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteInt16) {
      for (var i = 0; i < bytes.length; i += 2) {
        list.add(ByteData.view(bytes.buffer).getInt16(i, Endian.little));
      }
      return list.reshape<int>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteFloat16) {
      for (var i = 0; i < bytes.length; i += 2) {
        int float16 = ByteData.view(bytes.buffer).getUint16(i, Endian.little);
        double float32 = _float16ToFloat32(float16);
        list.add(float32);
      }
      return list.reshape<double>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteInt8) {
      for (var i = 0; i < bytes.length; i += 1) {
        list.add(ByteData.view(bytes.buffer).getInt8(i));
      }
      return list.reshape<int>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteUInt8) {
      for (var i = 0; i < bytes.length; i += 1) {
        list.add(ByteData.view(bytes.buffer).getUint8(i));
      }
      return list.reshape<int>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteInt64) {
      for (var i = 0; i < bytes.length; i += 8) {
        list.add(ByteData.view(bytes.buffer).getInt64(i));
      }
      return list.reshape<int>(shape);
    } else if (tensorType.value == TfLiteType.kTfLiteString) {
      list.add(decodeTFStrings(bytes));
      return list;
    }
    throw UnsupportedError("$tensorType is not Supported.");
  }

  static Uint8List floatToFloat16Bytes(double value) {
    int float16 = _float32ToFloat16(value);
    final ByteData byteDataBuffer = ByteData(2)
      ..setUint16(0, float16, Endian.little);
    return Uint8List.fromList(byteDataBuffer.buffer.asUint8List());
  }

  static int _float32ToFloat16(double value) {
    final Float32List float32Buffer = Float32List(1);
    final Uint32List int32Buffer = float32Buffer.buffer.asUint32List();

    float32Buffer[0] = value;
    int f = int32Buffer[0];
    int sign = (f >> 16) & 0x8000;
    int exponent = (f >> 23) & 0xFF;
    int mantissa = f & 0x007FFFFF;

    if (exponent == 0) return sign;
    if (exponent == 255) return sign | 0x7C00;

    exponent = exponent - 127 + 15;
    if (exponent >= 31) return sign | 0x7C00;
    if (exponent <= 0) return sign;

    // Implement rounding
    int roundMantissa = (mantissa >> 13) + ((mantissa >> 12) & 1);

    return sign | (exponent << 10) | roundMantissa;
  }

  static double bytesToFloat32(Uint8List bytes) {
    final ByteData byteDataBuffer = ByteData(2);
    int float16 = byteDataBuffer.buffer
        .asUint8List()
        .buffer
        .asByteData()
        .getUint16(0, Endian.little);
    return _float16ToFloat32(float16);
  }

  static double _float16ToFloat32(int value) {
    final Float32List float32Buffer = Float32List(1);
    final Uint32List int32Buffer = float32Buffer.buffer.asUint32List();

    int sign = (value & 0x8000) << 16;
    int exponent = (value & 0x7C00) >> 10;
    int mantissa = (value & 0x03FF) << 13;

    if (exponent == 0) {
      if (mantissa == 0) return sign == 0 ? 0.0 : -0.0;
      while ((mantissa & 0x00800000) == 0) {
        mantissa <<= 1;
        exponent -= 1;
      }
      exponent += 1;
    } else if (exponent == 31) {
      if (mantissa == 0) {
        return sign == 0 ? double.infinity : double.negativeInfinity;
      }
      return double.nan;
    }

    exponent = exponent - 15 + 127;
    int32Buffer[0] = sign | (exponent << 23) | mantissa;

    return float32Buffer[0];
  }
}
