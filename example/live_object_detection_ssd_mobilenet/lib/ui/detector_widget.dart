import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:live_object_detection_ssd_mobilenet/models/recognition.dart';
import 'package:live_object_detection_ssd_mobilenet/models/screen_params.dart';
import 'package:live_object_detection_ssd_mobilenet/service/detector_service.dart';
import 'package:live_object_detection_ssd_mobilenet/ui/box_widget.dart';
import 'package:live_object_detection_ssd_mobilenet/ui/stats_widget.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// [DetectorWidget] sends each frame for inference
class DetectorWidget extends StatefulWidget {
  /// Constructor
  const DetectorWidget({super.key});

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget>
    with WidgetsBindingObserver {
  /// List of available cameras
  late List<CameraDescription> cameras;

  /// Controller
  CameraController? _cameraController;

  // use only when initialized, so - not null
  get _controller => _cameraController;

  /// Object Detector is running on a background [Isolate]. This is nullable
  /// because acquiring a [Detector] is an asynchronous operation. This
  /// value is `null` until the detector is initialized.
  Detector? _detector;
  StreamSubscription? _subscription;

  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Map<String, String>? stats;

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  void _initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);
    // initialize preview and CameraImage stream
    _initializeCamera();
    // Spawn a new isolate
    await path_provider.getTemporaryDirectory().then((appDir) {
      Detector.start(appDir.path).then((instance) {
        setState(() {
          _detector = instance;
          _subscription = instance.resultsStream.stream.listen((values) {
            setState(() {
              results = values['recognitions'];
              stats = values['stats'];
            });
          });
        });
      });
    });
  }

  /// Initializes the camera by setting [_cameraController]
  void _initializeCamera() async {
    cameras = await availableCameras();
    // cameras[0] for back-camera
    _cameraController =
        CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false)
          ..initialize().then((_) async {
            // Stream of image passed to [onLatestImageAvailable] callback
            await _controller.startImageStream(onLatestImageAvailable);
            setState(() {});

            /// previewSize is size of each image frame captured by controller
            ///
            /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
            ScreenParams.previewSize = _controller.value.previewSize!;
          });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while the camera is not initialized
    if (_cameraController == null || !_controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    var aspect = _controller.value.aspectRatio;
    if (Platform.isAndroid) {
      aspect = 1 / aspect;
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: CameraPreview(_controller),
        ),
        // Stats
        _statsWidget(),
        // Bounding boxes
        AspectRatio(
          aspectRatio: aspect,
          child: _boundingBoxes(),
        ),
      ],
    );
  }

  Widget _statsWidget() => (stats != null)
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.white.withAlpha(150),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: stats!.entries
                    .map((e) => StatsWidget(e.key, e.value))
                    .toList(),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();

  /// Returns Stack of bounding boxes
  Widget _boundingBoxes() {
    if (results == null) {
      return const SizedBox.shrink();
    }
    return Stack(
        children: results!.map((box) => BoxWidget(result: box)).toList());
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  void onLatestImageAvailable(CameraImage cameraImage) async {
    _detector?.processFrame(cameraImage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _controller.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!_controller.value.isStreamingImages) {
          await _controller.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    super.dispose();
  }
}
