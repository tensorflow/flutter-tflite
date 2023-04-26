import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import '../bindings/delegates/gpu_delegate.dart';
import '../bindings/types.dart';
import '../delegate.dart';

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
        tfLiteGpuDelegateV2Create(nullptr),
      );
    }
    return GpuDelegateV2._(tfLiteGpuDelegateV2Create(options.base));
  }
  @override
  void delete() {
    checkState(!_deleted, message: 'TfLiteGpuDelegateV2 already deleted.');
    tfLiteGpuDelegateV2Delete(_delegate);
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
    TfLiteGpuInferenceUsage inferencePreference =
        TfLiteGpuInferenceUsage.fastSingleAnswer,
    TfLiteGpuInferencePriority inferencePriority1 =
        TfLiteGpuInferencePriority.maxPrecision,
    TfLiteGpuInferencePriority inferencePriority2 =
        TfLiteGpuInferencePriority.auto,
    TfLiteGpuInferencePriority inferencePriority3 =
        TfLiteGpuInferencePriority.auto,
    List<TfLiteGpuExperimentalFlags> experimentalFlags = const [
      TfLiteGpuExperimentalFlags.enableQuant
    ],
    int maxDelegatePartitions = 1,
  }) {
    return GpuDelegateOptionsV2._(TfLiteGpuDelegateOptionsV2.allocate(
      isPrecisionLossAllowed,
      inferencePreference,
      inferencePriority1,
      inferencePriority2,
      inferencePriority3,
      _TfLiteGpuExperimentalFlagsUtil.getBitmask(experimentalFlags),
      maxDelegatePartitions,
    ));
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

  static int value(TfLiteGpuExperimentalFlags flag) {
    switch (flag) {
      case TfLiteGpuExperimentalFlags.none:
        return none;
      case TfLiteGpuExperimentalFlags.enableQuant:
        return enableQuant;
      case TfLiteGpuExperimentalFlags.clOnly:
        return clOnly;
      case TfLiteGpuExperimentalFlags.glOnly:
        return glOnly;
    }
  }

  static int getBitmask(List<TfLiteGpuExperimentalFlags> flags) {
    int bitmask = 0;
    for (final flag in flags) {
      bitmask |= value(flag);
    }
    return bitmask;
  }
}
