import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Wraps a model interpreter.
class TfLiteInterpreter extends Opaque {}

/// Wraps customized interpreter configuration options.
class TfLiteInterpreterOptions extends Opaque {}

/// Wraps a loaded TensorFlowLite model.
class TfLiteModel extends Opaque {}

/// Wraps data associated with a graph tensor.
class TfLiteTensor extends Opaque {}

/// Wraps a TfLiteDelegate
class TfLiteDelegate extends Opaque {}

/// Wraps Quantization Params
class TfLiteQuantizationParams extends Struct {
  @Float()
  external double scale;

  @Int32()
  external int zeroPoint;

  @override
  String toString() {
    return 'TfLiteQuantizationParams{scale: $scale, zero_point: $zeroPoint}';
  }
}

/// Wraps gpu delegate options for iOS metal delegate
class TFLGpuDelegateOptions extends Struct {
  /// Allows to quantify tensors, downcast values, process in float16 etc.
  @Int32()
  external int allowPrecisionLoss;

  @Int32()
  external int waitType;

  // Allows execution of integer quantized models
  @Int32()
  external int enableQuantization;

  static Pointer<TFLGpuDelegateOptions> allocate(
    bool allowPrecisionLoss,
    TFLGpuDelegateWaitType waitType,
    bool enableQuantization,
  ) {
    final result = calloc<TFLGpuDelegateOptions>();
    result.ref
      ..allowPrecisionLoss = allowPrecisionLoss ? 1 : 0
      ..waitType = waitType.index
      ..enableQuantization = enableQuantization ? 1 : 0;
    return result;
  }
}

/// Wraps TfLiteGpuDelegateOptionsV2 for android gpu delegate
class TfLiteGpuDelegateOptionsV2 extends Struct {
  @Int32()
  external int isPrecisionLossAllowed;

  @Int32()
  external int inferencePreference;

  @Int32()
  external int inferencePriority1;
  @Int32()
  external int inferencePriority2;
  @Int32()
  external int inferencePriority3;

  @Int64()
  external int experimentalFlags;

  @Int32()
  external int maxDelegatedPartitions;

  static Pointer<TfLiteGpuDelegateOptionsV2> allocate(
      bool isPrecisionLossAllowed,
      TfLiteGpuInferenceUsage inferencePreference,
      TfLiteGpuInferencePriority inferencePriority1,
      TfLiteGpuInferencePriority inferencePriority2,
      TfLiteGpuInferencePriority inferencePriority3,
      int experimentalFlagsBitmask,
      int maxDelegatePartitions) {
    final result = calloc<TfLiteGpuDelegateOptionsV2>();
    result.ref
      ..isPrecisionLossAllowed = isPrecisionLossAllowed ? 1 : 0
      ..inferencePreference = inferencePreference.index
      ..inferencePriority1 = inferencePriority1.index
      ..inferencePriority2 = inferencePriority2.index
      ..inferencePriority3 = inferencePriority3.index
      ..experimentalFlags = experimentalFlagsBitmask
      ..maxDelegatedPartitions = maxDelegatePartitions;
    return result;
  }
}

/// Wraps TfLiteXNNPackDelegateOptions
class TfLiteXNNPackDelegateOptions extends Struct {
  @Int32()
  external int numThreads;

  static Pointer<TfLiteXNNPackDelegateOptions> allocate(int numThreads) {
    final result = calloc<TfLiteXNNPackDelegateOptions>();
    result.ref..numThreads = numThreads;
    return result;
  }
}

// Wraps TfLiteCoreMlDelegateOptions
class TfLiteCoreMlDelegateOptions extends Struct {
  @Int32()
  external int enabledDevices;

  @Int32()
  external int coremlVersion;

  @Int32()
  external int maxDelegatedPartitions;

  @Int32()
  external int minNodesPerPartition;

  static Pointer<TfLiteCoreMlDelegateOptions> allocate(
      TfLiteCoreMlDelegateEnabledDevices enabledDevices,
      int coremlVersion,
      int maxDelegatedPartitions,
      int minNodesPerPartition) {
    final result = calloc<TfLiteCoreMlDelegateOptions>();
    result.ref
      ..enabledDevices = enabledDevices.index
      ..coremlVersion = coremlVersion
      ..maxDelegatedPartitions = maxDelegatedPartitions
      ..minNodesPerPartition = minNodesPerPartition;
    return result;
  }
}

/// Status of a TensorFlowLite function call.
class TfLiteStatus {
  static const ok = 0;
  static const error = 1;
}

/// Types supported by tensor.
enum TfLiteType {
  none,
  float32,
  int32,
  uint8,
  int64,
  string,
  bool,
  int16,
  complex64,
  int8,
  float16
}

/// iOS metal delegate wait types.
enum TFLGpuDelegateWaitType {
  /// waitUntilCompleted
  passive,

  /// Minimize latency. It uses active spinning instead of mutex and consumes
  /// additional CPU resources.
  active,

  /// Useful when the output is used with GPU pipeline then or if external
  /// command encoder is set.
  doNotWait,

  /// Tries to avoid GPU sleep mode.
  aggressive,
}

// android gpu delegate
/// Encapsulated compilation/runtime tradeoffs.
enum TfLiteGpuInferenceUsage {
  /// Delegate will be used only once, therefore, bootstrap/init time should
  /// be taken into account.
  ///TFLITE_GPU_INFERENCE_PREFERENCE_FAST_SINGLE_ANSWER,
  fastSingleAnswer,

  /// Prefer maximizing the throughput. Same delegate will be used repeatedly on
  /// multiple inputs.
  /// TFLITE_GPU_INFERENCE_PREFERENCE_SUSTAINED_SPEED,
  preferenceSustainSpeed,
}

enum TfLiteGpuInferencePriority {
  /// AUTO priority is needed when a single priority is the most important
  /// factor. For example,
  /// priority1 = MIN_LATENCY would result in the configuration that achieves
  /// maximum performance.
  /// TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
  auto,

  /// TFLITE_GPU_INFERENCE_PRIORITY_MAX_PRECISION,
  maxPrecision,

  /// TFLITE_GPU_INFERENCE_PRIORITY_MIN_LATENCY,
  minLatency,

  /// TFLITE_GPU_INFERENCE_PRIORITY_MIN_MEMORY_USAGE,
  minMemoryUsage,
}

/// Used to toggle experimental flags used in the delegate. Note that this is a
/// bitmask, so the values should be 1, 2, 4, 8, ...etc.
enum TfLiteGpuExperimentalFlags {
  /// TFLITE_GPU_EXPERIMENTAL_FLAGS_NONE = 0,
  none,

  /// Enables inference on quantized models with the delegate.
  /// NOTE: This is enabled in TfLiteGpuDelegateOptionsV2Default.
  /// TFLITE_GPU_EXPERIMENTAL_FLAGS_ENABLE_QUANT = 1 << 0,
  enableQuant,

  /// Enforces execution with the provided backend.
  // TFLITE_GPU_EXPERIMENTAL_FLAGS_CL_ONLY = 1 << 1,
  clOnly,

  /// TFLITE_GPU_EXPERIMENTAL_FLAGS_GL_ONLY = 1 << 2
  glOnly,
}

enum TfLiteCoreMlDelegateEnabledDevices {
  /// Create Core ML delegate only on devices with Apple Neural Engine.
  ///
  /// Returns nullptr otherwise.
  TfLiteCoreMlDelegateDevicesWithNeuralEngine,

  /// Always create Core ML delegate
  TfLiteCoreMlDelegateAllDevices
}
