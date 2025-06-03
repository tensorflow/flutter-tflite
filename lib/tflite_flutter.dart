// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TensorFlow Lite for Flutter
library tflite_flutter;

import 'package:ffi/ffi.dart';
import 'package:tflite_flutter/src/bindings/bindings.dart';

export 'src/delegate.dart';
export 'src/delegates/gpu_delegate.dart';
export 'src/delegates/flex_delegate.dart';
export 'src/delegates/metal_delegate.dart';
export 'src/delegates/xnnpack_delegate.dart';
export 'src/delegates/coreml_delegate.dart';
export 'src/interpreter.dart';
export 'src/interpreter_options.dart';
export 'src/isolate_interpreter.dart';
export 'src/quanitzation_params.dart';
export 'src/tensor.dart';
export 'src/util/byte_conversion_utils.dart';
export 'src/util/list_shape_extension.dart';

/// tflite version information.
String get version => tfliteBinding.TfLiteVersion().cast<Utf8>().toDartString();
