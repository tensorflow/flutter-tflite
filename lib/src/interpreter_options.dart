import 'dart:ffi';
import 'dart:io';

import 'package:quiver/check.dart';
import '../tflite_flutter.dart';
import 'bindings/interpreter_options.dart';

import 'bindings/types.dart';
import 'delegate.dart';

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
