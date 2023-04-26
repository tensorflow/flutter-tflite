import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import '../bindings/delegates/xnnpack_delegate.dart';
import '../bindings/types.dart';
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
        tfliteXNNPackDelegateCreate(nullptr),
      );
    }
    return XNNPackDelegate._(tfliteXNNPackDelegateCreate(options.base));
  }

  @override
  void delete() {
    checkState(!_deleted, message: 'XNNPackDelegate already deleted.');
    tfliteXNNPackDelegateDelete(_delegate);
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
    return XNNPackDelegateOptions._(TfLiteXNNPackDelegateOptions.allocate(
      1,
    ));
  }

  void delete() {
    checkState(!_deleted, message: 'XNNPackDelegate already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
