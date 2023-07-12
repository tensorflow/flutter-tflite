import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:live_object_detection_ssd_mobilenet/tflite/detector.dart';
import 'package:live_object_detection_ssd_mobilenet/tflite/recognition.dart';
import 'package:live_object_detection_ssd_mobilenet/tflite/stats.dart';
import 'package:live_object_detection_ssd_mobilenet/ui/camera_view_singleton.dart';
import 'package:live_object_detection_ssd_mobilenet/utils/isolate_utils.dart';

/// [CameraView] sends each frame for inference
class CameraView extends StatefulWidget {
  /// Callback to pass results after inference to [HomeView]
  final Function(List<Recognition> recognitions) resultsCallback;

  /// Callback to inference stats to [HomeView]
  final Function(Stats stats) statsCallback;

  /// Constructor
  const CameraView(this.resultsCallback, this.statsCallback, {super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  /// List of available cameras
  late List<CameraDescription> cameras;

  /// Controller
  CameraController? _cameraController;
  // use only when initialized, so - not null
  get controller => _cameraController;

  /// true when inference is ongoing
  late bool predicting;

  /// Instance of [Detector]
  late Detector detector;

  /// Instance of [IsolateUtils]
  late IsolateUtils isolateUtils;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);
    // Spawn a new isolate
    isolateUtils = IsolateUtils();
    await isolateUtils.start();
    // Camera initialization
    initializeCamera();
    // Create an instance of detector to load model and labels
    detector = Detector();
    // Initially predicting = false
    predicting = false;
  }

  /// Initializes the camera by setting [_cameraController]
  void initializeCamera() async {
    cameras = await availableCameras();

    // cameras[0] for rear-camera
    _cameraController =
        CameraController(cameras[0], ResolutionPreset.max, enableAudio: false)
          ..initialize().then((_) async {
            // Stream of image passed to [onLatestImageAvailable] callback
            await controller.startImageStream(onLatestImageAvailable);

            /// previewSize is size of each image frame captured by controller
            ///
            /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
            Size previewSize = controller.value.previewSize!;

            /// previewSize is size of raw input image to the model
            CameraViewSingleton.screenSize = MediaQuery.sizeOf(context);
            CameraViewSingleton.inputImageSize = previewSize;
            CameraViewSingleton.ratio = CameraViewSingleton.screenSize.width / previewSize.height;
          });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while the camera is not initialized
    if (_cameraController == null || !controller.value.isInitialized) {
      return const Spacer();
    }

    var aspect = controller.value.aspectRatio;
    if (Platform.isAndroid) {
      aspect = 1 / aspect;
    }

    return AspectRatio(
      aspectRatio: aspect,
      child: CameraPreview(controller),
    );
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    if (detector.interpreter != null && detector.labels != null) {
      // If previous inference has not completed then return
      if (predicting) {
        return;
      }

      setState(() {
        predicting = true;
      });

      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

      // Data to be passed to inference isolate
      var isolateData = IsolateData(
          cameraImage, detector.interpreter.address, detector.labels);

      // We could have simply used the compute method as well however
      // it would be as in-efficient as we need to continuously passing data
      // to another isolate.

      /// perform inference in separate isolate
      Map<String, dynamic> inferenceResults = await inference(isolateData);

      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      // pass results to HomeView
      widget.resultsCallback(inferenceResults["recognitions"]);

      // pass stats to HomeView
      widget.statsCallback((inferenceResults["stats"] as Stats)
        ..totalElapsedTime = uiThreadInferenceElapsedTime);

      /// This can be used for testing purposes only
      // String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // await saveImage(inferenceResults["image"], timestamp);

      // set predicting to false to allow new frames
      setState(() {
        predicting = false;
      });
    }
  }

  /// Runs inference in another isolate
  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        controller.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!controller.value.isStreamingImages) {
          await controller.startImageStream(onLatestImageAvailable);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }
}
