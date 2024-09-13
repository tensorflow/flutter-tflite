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

import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';

final DynamicLibrary _dylib = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libtensorflowlite_jni.so');
  }

  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }

  if (Platform.isMacOS) {
    return DynamicLibrary.open(
        '${Directory(Platform.resolvedExecutable).parent.parent.path}/resources/libtensorflowlite_c-mac.dylib');
  }

  if (Platform.isLinux) {
    return DynamicLibrary.open(
        '${Directory(Platform.resolvedExecutable).parent.path}/blobs/libtensorflowlite_c-linux.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(
        '${Directory(Platform.resolvedExecutable).parent.path}/blobs/libtensorflowlite_c-win.dll');
  }

  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final DynamicLibrary _dylibGpu = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libtensorflowlite_gpu_jni.so');
  }

  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// TensorFlowLite Bindings
final tfliteBinding = TensorFlowLiteBindings(_dylib);

/// TensorFlowLite Gpu Bindings
final tfliteBindingGpu = TensorFlowLiteBindings(_dylibGpu);
