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

/// Quantization scale and zero point associated with a tensor.
class QuantizationParams {
  final double _scale;
  final int _zeroPoint;

  /// Creates quantization parameters with [scale] and [zeroPoint].
  QuantizationParams(this._scale, this._zeroPoint);

  /// Scale used to map quantized values to real values.
  double get scale => _scale;

  /// Zero point used to map quantized values to real values.
  int get zeroPoint => _zeroPoint;

  /// Returns a string representation of these parameters.
  @override
  String toString() {
    return 'QuantizationParams{_scale: $_scale, _zeroPoint: $_zeroPoint}';
  }
}
