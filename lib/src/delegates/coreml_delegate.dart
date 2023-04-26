import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import '../bindings/delegates/coreml_delegate.dart';
import '../bindings/types.dart';
import '../delegate.dart';

/// CoreMl Delegate
class CoreMlDelegate implements Delegate {
  Pointer<TfLiteDelegate> _delegate;
  bool _deleted = false;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  CoreMlDelegate._(this._delegate);

  factory CoreMlDelegate({CoreMlDelegateOptions? options}) {
    if (options == null) {
      return CoreMlDelegate._(
        tfliteCoreMlDelegateCreate(nullptr),
      );
    }
    return CoreMlDelegate._(tfliteCoreMlDelegateCreate(options.base));
  }

  @override
  void delete() {
    checkState(!_deleted, message: 'CoreMlDelegate already deleted.');
    tfliteCoreMlDelegateDelete(_delegate);
    _deleted = true;
  }
}

/// CoreMlDelegate Options
class CoreMlDelegateOptions {
  Pointer<TfLiteCoreMlDelegateOptions> _options;
  bool _deleted = false;

  Pointer<TfLiteCoreMlDelegateOptions> get base => _options;

  CoreMlDelegateOptions._(this._options);

  factory CoreMlDelegateOptions({
    TfLiteCoreMlDelegateEnabledDevices enabledDevices =
        TfLiteCoreMlDelegateEnabledDevices
            .TfLiteCoreMlDelegateDevicesWithNeuralEngine,
    int coremlVersion = 0,
    int maxDelegatedPartitions = 0,
    int minNodesPerPartition = 2,
  }) {
    return CoreMlDelegateOptions._(TfLiteCoreMlDelegateOptions.allocate(
      enabledDevices,
      coremlVersion,
      maxDelegatedPartitions,
      minNodesPerPartition,
    ));
  }

  void delete() {
    checkState(!_deleted, message: 'CoreMlDelegate already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
