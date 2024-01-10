import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:movinet/isolate_inference.dart';
import 'package:movinet/movinet_helper.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isProcessing = false;
  late MoviNetHelper _movinetHelper;
  late CameraDescription _cameraDescription;
  Category? _action;

  // init camera
  _initCamera() {
    _cameraDescription = _cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(
        _cameraDescription, ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420);
    _cameraController!.initialize().then((value) {
      _cameraController!.startImageStream(_imageAnalysis);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _imageAnalysis(CameraImage cameraImage) async {
    // if image is still analyze, skip this frame
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    final action = await _movinetHelper.classify(cameraImage);
    _isProcessing = false;
    if (mounted) {
      setState(() {
        _action = action;
      });
    }
  }

  // this function using config camera and init model
  _initHelper() async {
    _initCamera();
    _movinetHelper = MoviNetHelper();
    await _movinetHelper.initHelper();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initHelper();
    });
  }

  // handle app lifecycle state change (pause/resume)
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _cameraController?.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (_cameraController != null &&
            !_cameraController!.value.isStreamingImages) {
          await _cameraController!.startImageStream(_imageAnalysis);
        }
        break;
      default:
    }
  }

  // dispose camera
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _movinetHelper.close();
    super.dispose();
  }

  // camera widget to display camera preview and person
  Widget resultWidget(context) {
    if (_cameraController == null) return Container();
    return Stack(
      children: [
        CameraPreview(_cameraController!),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Text(
                      "Action: ${_action != null ? _action?.label : ''}",
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      "Score: ${_action != null ? _action?.score : ''}",
                      textAlign: TextAlign.left,
                    ),
                    TextButton(
                        onPressed: () {
                          _movinetHelper.clearState();
                        },
                        child: const Text("Clear")),
                  ],
                ))
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: resultWidget(context),
    );
  }
}
