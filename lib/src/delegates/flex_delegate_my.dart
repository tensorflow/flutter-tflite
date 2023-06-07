import 'dart:ffi';

import 'package:quiver/check.dart';
import '../bindings/bindings_flex.dart';
import '../bindings/tensorflow_lite_bindings_generated.dart';
import '../delegate.dart';

/// Author: cpoohee
/// https://github.com/cpoohee/tflite_flutter_plugin
/// Flex Delegate for Android
class Flex_Delegate implements Delegate {
  Pointer<TfLiteDelegate> _delegate;
  bool _deleted = false;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  Flex_Delegate._(this._delegate);

  factory Flex_Delegate() {
    return Flex_Delegate._(tfLite_flex_createDelegate());
  }

  @override
  void delete() {
    checkState(!_deleted,
        message: 'TfLiteFlex_delegate already deleted.');

    tfLite_flex_deleteDelegate(_delegate);
    _deleted = true;
  }
}