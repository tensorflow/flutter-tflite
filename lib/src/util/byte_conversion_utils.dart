import 'dart:typed_data';
import 'list_shape_extension.dart';
import 'package:tflite_flutter/src/bindings/types.dart';

class ByteConversionUtils {
  static Uint8List convertObjectToBytes(Object o, TfLiteType tfliteType) {
    if (o is Uint8List) {
      return o;
    }
    if (o is ByteBuffer) {
      return o.asUint8List();
    }
    List<int> bytes = <int>[];
    if (o is List) {
      for (var e in o) {
        bytes.addAll(convertObjectToBytes(e, tfliteType));
      }
    } else {
      return _convertElementToBytes(o, tfliteType);
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List _convertElementToBytes(Object o, TfLiteType tfliteType) {
    if (tfliteType == TfLiteType.float32) {
      if (o is double) {
        var buffer = Uint8List(4).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setFloat32(0, o, Endian.little);
        return buffer.asUint8List();
      } else {
        throw ArgumentError(
            'The input element is ${o.runtimeType} while tensor data tfliteType is ${TfLiteType.float32}');
      }
    } else if (tfliteType == TfLiteType.int32) {
      if (o is int) {
        var buffer = Uint8List(4).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt32(0, o, Endian.little);
        return buffer.asUint8List();
      } else {
        throw ArgumentError(
            'The input element is ${o.runtimeType} while tensor data tfliteType is ${TfLiteType.int32}');
      }
    } else if (tfliteType == TfLiteType.int64) {
      if (o is int) {
        var buffer = Uint8List(8).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt64(0, o, Endian.big);
        return buffer.asUint8List();
      } else {
        throw ArgumentError(
            'The input element is ${o.runtimeType} while tensor data tfliteType is ${TfLiteType.int32}');
      }
    } else if (tfliteType == TfLiteType.int16) {
      if (o is int) {
        var buffer = Uint8List(2).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt16(0, o, Endian.little);
        return buffer.asUint8List();
      } else {
        throw ArgumentError(
            'The input element is ${o.runtimeType} while tensor data tfliteType is ${TfLiteType.int32}');
      }
    } else if (tfliteType == TfLiteType.float16) {
      if (o is double) {
        var buffer = Uint8List(4).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setFloat32(0, o, Endian.little);
        return buffer.asUint8List().sublist(0, 2);
      } else {
        throw ArgumentError(
            'The input element is ${o.runtimeType} while tensor data tfliteType is ${TfLiteType.float32}');
      }
    } else if (tfliteType == TfLiteType.int8) {
      if (o is int) {
        var buffer = Uint8List(1).buffer;
        var bdata = ByteData.view(buffer);
        bdata.setInt8(0, o);
        return buffer.asUint8List();
      } else {
        throw ArgumentError(
            'The input element is ${o.runtimeType} while tensor data tfliteType is ${TfLiteType.float32}');
      }
    } else {
      throw ArgumentError(
          'The input data tfliteType ${o.runtimeType} is unsupported');
    }
  }

  static Object convertBytesToObject(
      Uint8List bytes, TfLiteType tfliteType, List<int> shape) {
    // stores flattened data
    List<dynamic> list = [];
    if (tfliteType == TfLiteType.int32) {
      for (var i = 0; i < bytes.length; i += 4) {
        list.add(ByteData.view(bytes.buffer).getInt32(i, Endian.little));
      }
      return list.reshape<int>(shape);
    } else if (tfliteType == TfLiteType.float32) {
      for (var i = 0; i < bytes.length; i += 4) {
        list.add(ByteData.view(bytes.buffer).getFloat32(i, Endian.little));
      }
      return list.reshape<double>(shape);
    } else if (tfliteType == TfLiteType.int16) {
      for (var i = 0; i < bytes.length; i += 2) {
        list.add(ByteData.view(bytes.buffer).getInt16(i, Endian.little));
      }
      return list.reshape<int>(shape);
    } else if (tfliteType == TfLiteType.float16) {
      Uint8List list32 = Uint8List(bytes.length * 2);
      for (var i = 0; i < bytes.length; i += 2) {
        list32[i] = bytes[i];
        list32[i + 1] = bytes[i + 1];
      }
      for (var i = 0; i < list32.length; i += 4) {
        list.add(ByteData.view(list32.buffer).getFloat32(i, Endian.little));
      }
      return list.reshape<double>(shape);
    } else if (tfliteType == TfLiteType.int8) {
      for (var i = 0; i < bytes.length; i += 1) {
        list.add(ByteData.view(bytes.buffer).getInt8(i));
      }
      return list.reshape<int>(shape);
    } else if (tfliteType == TfLiteType.uint8) {
      for (var i = 0; i < bytes.length; i += 1) {
        list.add(ByteData.view(bytes.buffer).getUint8(i));
      }
      return list.reshape<int>(shape);
    } else if (tfliteType == TfLiteType.int64) {
      for (var i = 0; i < bytes.length; i += 8) {
        list.add(ByteData.view(bytes.buffer).getInt64(i));
      }
      return list.reshape<int>(shape);
    }
    throw UnsupportedError("$tfliteType is not Supported.");
  }
}
