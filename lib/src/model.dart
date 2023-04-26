import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';

import 'bindings/model.dart';
import 'bindings/types.dart';
import 'ffi/helper.dart';

/// TensorFlowLite model.
class Model {
  final Pointer<TfLiteModel> _model;
  bool _deleted = false;

  Pointer<TfLiteModel> get base => _model;

  Model._(this._model);

  /// Loads model from a file or throws if unsuccessful.
  factory Model.fromFile(String path) {
    final cpath = path.toNativeUtf8();
    final model = tfLiteModelCreateFromFile(cpath);
    calloc.free(cpath);
    checkArgument(isNotNull(model),
        message: 'Unable to create model from file');
    return Model._(model);
  }

  /// Loads model from a buffer or throws if unsuccessful.
  factory Model.fromBuffer(Uint8List buffer) {
    final size = buffer.length;
    final ptr = calloc<Uint8>(size);
    final externalTypedData = ptr.asTypedList(size);
    externalTypedData.setRange(0, buffer.length, buffer);
    final model = tfLiteModelCreateFromBuffer(ptr.cast(), buffer.length);
    checkArgument(isNotNull(model),
        message: 'Unable to create model from buffer');
    return Model._(model);
  }

  /// Destroys the model instance.
  void delete() {
    checkState(!_deleted, message: 'Model already deleted.');
    tfLiteModelDelete(_model);
    _deleted = true;
  }
}
