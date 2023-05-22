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
import 'package:quiver/check.dart';
import 'package:tflite_flutter/src/bindings/bindings.dart';
import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Metal Delegate for iOS
class GpuDelegate implements Delegate {
  Pointer<TfLiteDelegate> _delegate;
  bool _deleted = false;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  GpuDelegate._(this._delegate);

  factory GpuDelegate({GpuDelegateOptions? options}) {
    if (options == null) {
      return GpuDelegate._(
        tfliteBinding.TFLGpuDelegateCreate(nullptr),
      );
    }
    return GpuDelegate._(tfliteBinding.TFLGpuDelegateCreate(options.base));
  }

  @override
  void delete() {
    checkState(!_deleted, message: 'TfLiteGpuDelegate already deleted.');
    tfliteBinding.TFLGpuDelegateDelete(_delegate);
    _deleted = true;
  }
}

/// Metal Delegate options
class GpuDelegateOptions {
  Pointer<TFLGpuDelegateOptions> _options;
  bool _deleted = false;

  Pointer<TFLGpuDelegateOptions> get base => _options;

  GpuDelegateOptions._(this._options);

  factory GpuDelegateOptions({
    bool allowPrecisionLoss = false,
    int waitType = TFLGpuDelegateWaitType.TFLGpuDelegateWaitTypePassive,
    bool enableQuantization = true,
  }) {
    final options = calloc<TFLGpuDelegateOptions>();

    options.ref
      ..allow_precision_loss = allowPrecisionLoss
      ..wait_type = waitType
      ..enable_quantization = enableQuantization;

    return GpuDelegateOptions._(options);
  }

  void delete() {
    checkState(!_deleted, message: 'TfLiteGpuDelegate already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
