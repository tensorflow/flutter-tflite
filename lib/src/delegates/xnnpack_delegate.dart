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

import '../delegate.dart';

/// XNNPack Delegate
class XNNPackDelegate implements Delegate {
  Pointer<TfLiteDelegate> _delegate;
  bool _deleted = false;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  XNNPackDelegate._(this._delegate);

  factory XNNPackDelegate({XNNPackDelegateOptions? options}) {
    if (options == null) {
      return XNNPackDelegate._(
        tfliteBinding.TfLiteXNNPackDelegateCreate(nullptr),
      );
    }
    return XNNPackDelegate._(
        tfliteBinding.TfLiteXNNPackDelegateCreate(options.base));
  }

  @override
  void delete() {
    checkState(!_deleted, message: 'XNNPackDelegate already deleted.');
    tfliteBinding.TfLiteXNNPackDelegateDelete(_delegate);
    _deleted = true;
  }
}

/// XNNPackDelegate Options
class XNNPackDelegateOptions {
  Pointer<TfLiteXNNPackDelegateOptions> _options;
  bool _deleted = false;

  Pointer<TfLiteXNNPackDelegateOptions> get base => _options;

  XNNPackDelegateOptions._(this._options);

  factory XNNPackDelegateOptions({
    int numThreads = 1,
  }) {
    final options = calloc<TfLiteXNNPackDelegateOptions>();
    options.ref.num_threads = numThreads;

    return XNNPackDelegateOptions._(options);
  }

  void delete() {
    checkState(!_deleted, message: 'XNNPackDelegate already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
