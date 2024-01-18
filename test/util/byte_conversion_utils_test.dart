import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  group('convertObjectToBytes and convertBytesToObject', () {
    test('TensorType.float32', () async {
      var bytes =
          ByteConversionUtils.convertObjectToBytes(1.1, TensorType.float32);
      expect(bytes, [205, 204, 140, 63]);
      var object = ByteConversionUtils.convertBytesToObject(
          bytes, TensorType.float32, [1]) as List;
      expect(object[0], closeTo(1.1, 0.0001));
    });

    test('TensorType.float16', () async {
      var bytes =
          ByteConversionUtils.convertObjectToBytes(1.1, TensorType.float16);
      expect(bytes, [102, 60]);
      var object = ByteConversionUtils.convertBytesToObject(
          bytes, TensorType.float16, [1]) as List;
      expect(object[0], closeTo(1.1, 0.001));

      /*
      ```python
      import tensorflow as tf

      for value in [1.2, 1.3, 1.4, 1.5]:
          value_tf = tf.constant(value, dtype=tf.float16)
          byte_data_tf = tf.io.serialize_tensor(value_tf)
          last_two_bytes_tf = byte_data_tf.numpy()[-2:]  # Get the last two bytes
          print([x for x in last_two_bytes_tf], value_tf.numpy().item())  # [0, 62] 1.5
      ```

      [205, 60] 1.2001953125
      [51, 61] 1.2998046875
      [154, 61] 1.400390625
      [0, 62] 1.5
       */

      List<double> values = [1.2, 1.3, 1.4, 1.5];
      List<List<int>> bytesList = [
        [205, 60],
        [51, 61],
        [154, 61],
        [0, 62]
      ];

      for (int i = 0; i < values.length; i++) {
        var bytes = ByteConversionUtils.convertObjectToBytes(
            values[i], TensorType.float16);
        expect(bytes, bytesList[i]);
        var object = ByteConversionUtils.convertBytesToObject(
            bytes, TensorType.float16, [1]) as List;
        expect(object[0], closeTo(values[i], 0.001));
      }
    });

    test('TensorType.int64', () async {
      var bytes = ByteConversionUtils.convertObjectToBytes(1, TensorType.int64);
      expect(bytes, [0, 0, 0, 0, 0, 0, 0, 1]);
      var object =
          ByteConversionUtils.convertBytesToObject(bytes, TensorType.int64, [1])
              as List;
      expect(object[0], 1);
    });

    test('TensorType.int32', () async {
      var bytes = ByteConversionUtils.convertObjectToBytes(1, TensorType.int32);
      expect(bytes, [1, 0, 0, 0]);
      var object =
          ByteConversionUtils.convertBytesToObject(bytes, TensorType.int32, [1])
              as List;
      expect(object[0], 1);
    });

    test('TensorType.int16', () async {
      var bytes = ByteConversionUtils.convertObjectToBytes(1, TensorType.int16);
      expect(bytes, [1, 0]);
      var object =
          ByteConversionUtils.convertBytesToObject(bytes, TensorType.int16, [1])
              as List;
      expect(object[0], 1);
    });

    test('TensorType.int8', () async {
      var bytes = ByteConversionUtils.convertObjectToBytes(1, TensorType.int8);
      expect(bytes, [1]);
      var object =
          ByteConversionUtils.convertBytesToObject(bytes, TensorType.int8, [1])
              as List;
      expect(object[0], 1);
    });

    test('TensorType.uint8', () async {
      var bytes = ByteConversionUtils.convertObjectToBytes(1, TensorType.uint8);
      expect(bytes, [1]);
      var object =
          ByteConversionUtils.convertBytesToObject(bytes, TensorType.uint8, [1])
              as List;
      expect(object[0], 1);
    });
  });

  group('errors', () {
    test('float to int8', () async {
      expect(
          () => ByteConversionUtils.convertObjectToBytes(1.1, TensorType.int8),
          throwsA(isA<ByteConversionError>()));
    });

    test('float to None', () async {
      expect(
          () =>
              ByteConversionUtils.convertObjectToBytes(1.1, TensorType.noType),
          throwsA(isA<ArgumentError>()));
    });
  });
}
