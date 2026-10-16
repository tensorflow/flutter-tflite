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

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_core/src/bindings/bindings.dart';
import 'package:tflite_core/src/bindings/tensorflow_lite_bindings_generated.dart';
import 'package:tflite_core/tflite_core.dart';

/// Core ML delegate for accelerating inference on Apple platforms.
class CoreMlDelegate implements Delegate {
  Pointer<TfLiteDelegate> _delegate;
  bool _deleted = false;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  CoreMlDelegate._(this._delegate);

  /// Creates a Core ML delegate, optionally configured with [options].
  factory CoreMlDelegate({CoreMlDelegateOptions? options}) {
    final delegateOptions = options ?? CoreMlDelegateOptions();

    return CoreMlDelegate._(
      tfliteBinding.TfLiteCoreMlDelegateCreate(delegateOptions.base),
    );
  }

  @override
  void delete() {
    checkState(!_deleted, message: 'CoreMlDelegate already deleted.');
    tfliteBinding.TfLiteCoreMlDelegateDelete(_delegate);
    _deleted = true;
  }
}

/// Options for configuring a Core ML delegate.
class CoreMlDelegateOptions {
  Pointer<TfLiteCoreMlDelegateOptions> _options;
  bool _deleted = false;

  Pointer<TfLiteCoreMlDelegateOptions> get base => _options;

  CoreMlDelegateOptions._(this._options);

  /// Creates Core ML options.
  ///
  /// [enabledDevices] selects the device class used for inference.
  /// [coremlVersion] selects a Core ML version, or zero for the default.
  /// [maxDelegatedPartitions] limits delegated graph partitions, or zero for
  /// the default.
  /// [minNodesPerPartition] is the minimum number of nodes in a partition.
  factory CoreMlDelegateOptions({
    int enabledDevices =
        TfLiteCoreMlDelegateEnabledDevices.TfLiteCoreMlDelegateDevicesWithNeuralEngine,
    int coremlVersion = 0,
    int maxDelegatedPartitions = 0,
    int minNodesPerPartition = 2,
  }) {
    final options = calloc<TfLiteCoreMlDelegateOptions>();

    options.ref
      ..enabled_devices = enabledDevices
      ..coreml_version = coremlVersion
      ..max_delegated_partitions = maxDelegatedPartitions
      ..min_nodes_per_partition = minNodesPerPartition;

    return CoreMlDelegateOptions._(options);
  }

  /// Releases the native options.
  void delete() {
    checkState(!_deleted, message: 'CoreMlDelegate already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
