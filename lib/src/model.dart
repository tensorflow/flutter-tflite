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
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter/src/bindings/bindings.dart';
import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';

import 'ffi/helper.dart';

/// TensorFlowLite model.
class Model {
  final Pointer<TfLiteModel> _model;
  bool _deleted = false;

  Pointer<TfLiteModel> get base => _model;

  Model._(this._model);

  /// Loads model from a file or throws if unsuccessful.
  factory Model.fromFile(String path) {
    final cpath = path.toNativeUtf8().cast<Char>();
    final model = tfliteBinding.TfLiteModelCreateFromFile(cpath);
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
    final model = tfliteBinding.TfLiteModelCreate(ptr.cast(), buffer.length);
    checkArgument(isNotNull(model),
        message: 'Unable to create model from buffer');
    return Model._(model);
  }

  /// Destroys the model instance.
  void delete() {
    checkState(!_deleted, message: 'Model already deleted.');
    tfliteBinding.TfLiteModelDelete(_model);
    _deleted = true;
  }
}
