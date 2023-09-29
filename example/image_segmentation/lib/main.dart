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

import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_segmentation/helper/image_segmentation_helper.dart';
import 'package:image/image.dart' as image_lib;
import 'dart:ui' as ui;

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // get available cameras
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Segmentation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Image Segmentation Home Page'),
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
  late CameraDescription _cameraDescription;
  late ImageSegmentationHelper _imageSegmentationHelper;
  ui.Image? _displayImage;
  List<int>? _labelsIndex;

  Future<void> _initCamera() async {
    _cameraDescription = _cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(
        _cameraDescription, ResolutionPreset.medium,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
        enableAudio: false);
    await _cameraController!.initialize().then((value) {
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
    // run image segmentation
    final masks =
        await _imageSegmentationHelper.inferenceCameraFrame(cameraImage);
    _isProcessing = false;
    if (mounted) {
      // convert mask to image, if Platform is Android we need to swap width
      // and height because camera image in android is landscape
      _convertToImage(
          masks,
          Platform.isIOS ? cameraImage.width : cameraImage.height,
          Platform.isIOS ? cameraImage.height : cameraImage.width);
    }
  }

  _initHelper() {
    _imageSegmentationHelper = ImageSegmentationHelper();
    _imageSegmentationHelper.initHelper();
    _initCamera();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initHelper();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _imageSegmentationHelper.close();
    super.dispose();
  }

  // convert output mask to image
  void _convertToImage(List<List<List<double>>>? masks, int originImageWidth,
      int originImageHeight) async {
    if (masks == null) return null;
    final width = masks.length;
    final height = masks.first.length;
    // store image matrix
    List<int> imageMatrix = [];
    // store labels index to display on screen
    final labelsIndex = <int>{};

    for (int i = 0; i < width; i++) {
      final List<List<double>> row = masks[i];
      for (int j = 0; j < height; j++) {
        final List<double> score = row[j];
        // find index of max score
        int maxIndex = 0;
        double maxScore = score[0];
        for (int k = 1; k < score.length; k++) {
          if (score[k] > maxScore) {
            maxScore = score[k];
            maxIndex = k;
          }
        }
        labelsIndex.add(maxIndex);
        // if max index is 0, it means background
        if (maxIndex == 0) {
          imageMatrix.addAll([0, 0, 0, 0]);
          continue;
        }

        // get color from label color
        final color = ImageSegmentationHelper.labelColors[maxIndex];
        // convert color to r,g,b
        final r = (color & 0x00ff0000) >> 16;
        final g = (color & 0x0000ff00) >> 8;
        final b = (color & 0x000000ff);
        // alpha 50%
        imageMatrix.addAll([r, g, b, 127]);
      }
    }

    // convert image matrix to image
    image_lib.Image convertedImage = image_lib.Image.fromBytes(
        width: width,
        height: height,
        bytes: Uint8List.fromList(imageMatrix).buffer,
        numChannels: 4);

    // resize output image to match original image
    final resizeImage = image_lib.copyResize(convertedImage,
        width: originImageWidth, height: originImageHeight);

    // convert image to ui.Image to display on screen
    final bytes = image_lib.encodePng(resizeImage);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _displayImage = frameInfo.image;
      _labelsIndex = labelsIndex.toList();
    });
  }

  Widget cameraWidget(context) {
    if (_cameraController == null) return Container();
    // calculate scale to fit output image to screen
    var scale = 1.0;
    if (_displayImage != null) {
      final minOutputSize = _displayImage!.width > _displayImage!.height
          ? _displayImage!.height
          : _displayImage!.width;
      final minScreenSize =
          MediaQuery.of(context).size.width > MediaQuery.of(context).size.height
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.width;
      scale = minScreenSize / minOutputSize;
    }
    return Stack(
      children: [
        CameraPreview(_cameraController!),
        if (_displayImage != null)
          Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: OverlayPainter()..updateImage(_displayImage!),
            ),
          ),
        if (_labelsIndex != null)
          // Align bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _labelsIndex!.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // parse color from label color
                    color: Color(ImageSegmentationHelper
                            .labelColors[_labelsIndex![index]])
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _imageSegmentationHelper
                        .getLabelsName(_labelsIndex![index]),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset('assets/images/tfl_logo.png'),
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: cameraWidget(context),
    );
  }
}

// OverlayPainter is used to draw mask on top of camera preview
class OverlayPainter extends CustomPainter {
  late final ui.Image image;

  updateImage(ui.Image image) {
    this.image = image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
