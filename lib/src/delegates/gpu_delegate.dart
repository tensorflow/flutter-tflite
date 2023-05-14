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
import 'package:tflite_flutter/src/bindings/bindings.dart';
import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// GPU delegate for Android
class GpuDelegateV2 implements Delegate {
  Pointer<TfLiteDelegate> _delegate;
  bool _deleted = false;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  GpuDelegateV2._(this._delegate);

  /// Creates [GpuDelegateV2] using the specified [options]
  /// uses [GpuDelegateOptionsV2.defaultOptions()] if options not
  /// specified.
  factory GpuDelegateV2({GpuDelegateOptionsV2? options}) {
    if (options == null) {
      return GpuDelegateV2._(
        tfliteBindingGpu.TfLiteGpuDelegateV2Create(nullptr),
      );
    }
    return GpuDelegateV2._(
        tfliteBindingGpu.TfLiteGpuDelegateV2Create(options.base));
  }
  @override
  void delete() {
    checkState(!_deleted, message: 'TfLiteGpuDelegateV2 already deleted.');
    tfliteBindingGpu.TfLiteGpuDelegateV2Delete(_delegate);
    _deleted = true;
  }
}

/// GPU delegate options for Android
class GpuDelegateOptionsV2 {
  Pointer<TfLiteGpuDelegateOptionsV2> _options;
  bool _deleted = false;

  Pointer<TfLiteGpuDelegateOptionsV2> get base => _options;
  GpuDelegateOptionsV2._(this._options);

  /// Creates GpuDelegateOptionsV2 with specified parameters
  ///
  /// [isPrecisionLossAllowed]
  /// When set to zero, computations are carried out in maximal possible
  /// precision. Otherwise, the GPU may quantify tensors, downcast values,
  /// process in FP16 to increase performance. For most models precision loss is
  /// warranted.
  ///
  /// [inferencePreference]
  /// Preference is defined in [TfLiteGpuInferenceUsage].
  ///
  /// [inferencePriority1] [inferencePriority2] [inferencePriority3]
  /// Ordered priorities provide better control over desired semantics,
  /// where priority(n) is more important than priority(n+1), therefore,
  /// each time inference engine needs to make a decision, it uses
  /// ordered priorities to do so.
  ///
  /// For example:
  ///   MAX_PRECISION at priority1 would not allow to decrease precision,
  ///   but moving it to priority2 or priority3 would result in F16 calculation.
  ///
  /// Priority is defined in TfLiteGpuInferencePriority.
  ///
  /// AUTO priority can only be used when higher priorities are fully specified.
  ///
  /// For example:
  ///   VALID:   priority1 = MIN_LATENCY, priority2 = AUTO, priority3 = AUTO
  ///
  ///   VALID:   priority1 = MIN_LATENCY, priority2 = MAX_PRECISION,
  ///            priority3 = AUTO
  ///
  ///   INVALID: priority1 = AUTO, priority2 = MIN_LATENCY, priority3 = AUTO
  ///
  ///   INVALID: priority1 = MIN_LATENCY, priority2 = AUTO,
  ///            priority3 = MAX_PRECISION
  ///
  /// Invalid priorities will result in error.
  ///
  ///
  /// [experimentalFlags] List of flags to enable.
  /// See the comments in [TfLiteGpuExperimentalFlags].
  ///
  /// [maxDelegatePartitions] A graph could have multiple partitions that can be
  /// delegated to the GPU.
  /// This limits the maximum number of partitions to be delegated. By default,
  /// it's set to 1 in TfLiteGpuDelegateOptionsV2Default().
  factory GpuDelegateOptionsV2({
    bool isPrecisionLossAllowed = false,
    int inferencePreference = TfLiteGpuInferenceUsage
        .TFLITE_GPU_INFERENCE_PREFERENCE_FAST_SINGLE_ANSWER,
    int inferencePriority1 =
        TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_MAX_PRECISION,
    int inferencePriority2 =
        TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
    int inferencePriority3 =
        TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
    List<int> experimentalFlags = const [
      TfLiteGpuExperimentalFlags.TFLITE_GPU_EXPERIMENTAL_FLAGS_ENABLE_QUANT
    ],
    int maxDelegatePartitions = 1,
  }) {
    final options = calloc<TfLiteGpuDelegateOptionsV2>();
    options.ref
      ..is_precision_loss_allowed = isPrecisionLossAllowed ? 1 : 0
      ..inference_preference = inferencePreference
      ..inference_priority1 = inferencePriority1
      ..inference_priority2 = inferencePriority2
      ..inference_priority3 = inferencePriority3
      ..experimental_flags =
          _TfLiteGpuExperimentalFlagsUtil.getBitmask(experimentalFlags)
      ..max_delegated_partitions = maxDelegatePartitions;

    return GpuDelegateOptionsV2._(options);
  }

  void delete() {
    checkState(!_deleted, message: 'TfLiteGpuDelegateV2 already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}

class _TfLiteGpuExperimentalFlagsUtil {
  static const int none = 0;
  static const int enableQuant = 1 << 0;
  static const int clOnly = 1 << 1;
  static const int glOnly = 1 << 2;

  static int value(int flag) {
    switch (flag) {
      case TfLiteGpuExperimentalFlags
            .TFLITE_GPU_EXPERIMENTAL_FLAGS_ENABLE_QUANT:
        return enableQuant;
      case TfLiteGpuExperimentalFlags.TFLITE_GPU_EXPERIMENTAL_FLAGS_CL_ONLY:
        return clOnly;
      case TfLiteGpuExperimentalFlags.TFLITE_GPU_EXPERIMENTAL_FLAGS_GL_ONLY:
        return glOnly;
      default:
        return none;
    }
  }

  static int getBitmask(List<int> flags) {
    int bitmask = 0;
    for (final flag in flags) {
      bitmask |= value(flag);
    }
    return bitmask;
  }
}
