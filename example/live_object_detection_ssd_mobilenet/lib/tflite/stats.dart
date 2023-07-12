/// Bundles different elapsed times
class Stats {
  /// Total time taken to convert CameraImage to Image
  int conversionTime;

  /// Total time taken in the isolate where the inference runs
  int analysisTime;

  /// [analysisTime] + communication overhead time
  /// between main isolate and another isolate
  int totalElapsedTime;

  /// Time for which inference runs
  int inferenceTime;

  /// Time taken to pre-process the image
  int preProcessingTime;

  Stats({
    required this.conversionTime,
    required this.preProcessingTime,
    required this.inferenceTime,
    required this.analysisTime,
    required this.totalElapsedTime,
  });

  @override
  String toString() {
    return 'Stats{conversionTime: $conversionTime, preProcessingTime: $preProcessingTime, '
        'inferenceTime: $inferenceTime, analysisTime: $analysisTime, totalElapsedTime: $totalElapsedTime}';
  }
}
