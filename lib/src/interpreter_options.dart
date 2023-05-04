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
import 'dart:io';

import 'package:quiver/check.dart';
import '../tflite_flutter.dart';
import 'bindings/interpreter_options.dart';

/// TensorFlowLite interpreter options.
class InterpreterOptions {
  final Pointer<TfLiteInterpreterOptions> _options;
  bool _deleted = false;

  Pointer<TfLiteInterpreterOptions> get base => _options;

  InterpreterOptions._(this._options);

  /// Creates a new options instance.
  factory InterpreterOptions() =>
      InterpreterOptions._(tfLiteInterpreterOptionsCreate());

  /// Destroys the options instance.
  void delete() {
    checkState(!_deleted, message: 'InterpreterOptions already deleted.');
    tfLiteInterpreterOptionsDelete(_options);
    _deleted = true;
  }

  /// Sets the number of CPU threads to use.
  set threads(int threads) =>
      tfLiteInterpreterOptionsSetNumThreads(_options, threads);

  /// TensorFlow version >= v2.2
  /// Set true to use NnApi Delegate for Android
  set useNnApiForAndroid(bool useNnApi) {
    if (Platform.isAndroid) {
      tfLiteInterpreterOptionsSetUseNNAPI(_options, useNnApi ? 1 : 0);
    }
  }

  /// Set true to use Metal Delegate for iOS
  set useMetalDelegateForIOS(bool useMetal) {
    if (Platform.isIOS) {
      addDelegate(GpuDelegate());
    }
  }

  /// Adds delegate to Interpreter Options
  void addDelegate(Delegate delegate) {
    tfLiteInterpreterOptionsAddDelegate(_options, delegate.base);
  }

// Unimplemented:
// TfLiteInterpreterOptionsSetErrorReporter
// TODO: TfLiteInterpreterOptionsSetErrorReporter
// TODO: setAllowFp16PrecisionForFp32(bool allow)

// setAllowBufferHandleOutput(bool allow)
}
