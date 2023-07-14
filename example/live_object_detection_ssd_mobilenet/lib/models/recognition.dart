
import 'package:flutter/cupertino.dart';
import 'package:live_object_detection_ssd_mobilenet/models/screen_params.dart';

/// Represents the recognition output from the model
class Recognition {
  /// Index of the result
  final int _id;

  /// Label of the result
  final String _label;

  /// Confidence [0.0, 1.0]
  final double _score;

  /// Location of bounding box rect
  ///
  /// The rectangle corresponds to the raw input image
  /// passed for inference
  final Rect _location;

  Recognition(this._id, this._label, this._score, this._location);

  int get id => _id;

  String get label => _label;

  double get score => _score;

  Rect get location => _location;

  /// Returns bounding box rectangle corresponding to the
  /// displayed image on screen
  ///
  /// This is the actual location where rectangle is rendered on
  /// the screen
  Rect get renderLocation {
    final double x1 = location.left;
    final double y1 = location.top;
    final double x2 = location.right;
    final double y2 = location.bottom;
    final double scaleX = ScreenParams.screenPreviewSize.width / 300;
    final double scaleY = ScreenParams.screenPreviewSize.height / 300;
    final double xDelta = (x2 - x1) * scaleX;
    final double yDelta = (y2 - y1) * scaleY;
    return Rect.fromLTRB(
      x1 * scaleX,
      y1 * scaleY,
      x1 * scaleX + xDelta,
      y1 * scaleY + yDelta,
    );
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
