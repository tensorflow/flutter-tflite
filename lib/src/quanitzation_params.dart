class QuantizationParams {
  final double _scale;
  final int _zeroPoint;

  QuantizationParams(this._scale, this._zeroPoint);

  double get scale => _scale;

  int get zeroPoint => _zeroPoint;

  @override
  String toString() {
    return 'QuantizationParams{_scale: $_scale, _zeroPoint: $_zeroPoint}';
  }
}
