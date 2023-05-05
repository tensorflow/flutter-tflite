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

const Set<String> _supported = {'linux', 'mac', 'win'};

String get binaryName {
  String os, ext;
  if (Platform.isLinux) {
    os = 'linux';
    ext = 'so';
  } else if (Platform.isMacOS) {
    os = 'mac';
    ext = 'so';
  } else if (Platform.isWindows) {
    os = 'win';
    ext = 'dll';
  } else {
    throw Exception('Unsupported platform!');
  }

  if (!_supported.contains(os)) {
    throw UnsupportedError('Unsupported platform: $os!');
  }

  return 'libtensorflowlite_c-$os.$ext';
}

/// TensorFlowLite C library.
// ignore: missing_return
DynamicLibrary tflitelib = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libtensorflowlite_c.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.process();
  } else {
    return DynamicLibrary.open(
        '${Directory(Platform.resolvedExecutable).parent.path}/blobs/$binaryName');
  }
}();
