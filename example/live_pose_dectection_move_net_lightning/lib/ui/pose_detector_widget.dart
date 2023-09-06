import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:live_pose_dectection_move_net_lightning/ml/movenet.dart';
import 'package:live_pose_dectection_move_net_lightning/ui/detector_widget..dart';
import 'package:live_pose_dectection_move_net_lightning/ui/painters/my_painter.dart';
import 'package:rxdart/rxdart.dart';

class PoseDetectorWidget extends StatefulWidget {
  const PoseDetectorWidget({super.key});

  @override
  State<StatefulWidget> createState() => _PoseDetectorWidgetState();
}

class _PoseDetectorWidgetState extends State<PoseDetectorWidget>
    with WidgetsBindingObserver {
  final Movenet _poseDetector = Movenet();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.back;
  StreamSubscription? resultsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStateAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _canProcess = false;
    _poseDetector.close();
    resultsStream?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _poseDetector.close();
        await resultsStream?.cancel();
        break;
      case AppLifecycleState.resumed:
        _isBusy = false;
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetectorWidget(
      title: 'Pose Detector',
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  Future<void> _processImage(CameraImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    await _poseDetector.detectPerson(inputImage);
  }

  void _initStateAsync() async {
    await _poseDetector.getModel();
    resultsStream = _poseDetector.resultsStream?.stream
        .debounceTime(
      const Duration(milliseconds: 50),
    )
        .listen((poses) async {
      if (poses == null) return;
      final painter = MyPainter(
        listPersons: [poses],
      );
      _customPaint = CustomPaint(
        painter: painter,
      );

      _isBusy = false;
      if (mounted) {
        setState(() {});
      }
    });
  }
}
