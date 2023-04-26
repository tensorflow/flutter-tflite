import 'dart:ffi';

import 'bindings/types.dart';

abstract class Delegate {
  /// Get pointer to TfLiteDelegate
  Pointer<TfLiteDelegate> get base;

  /// Destroys delegate instance
  void delete();
}
