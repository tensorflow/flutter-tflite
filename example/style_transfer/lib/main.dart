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
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const predictionModelPath =
      'assets/models/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite';
  static const transferModelPath =
      'assets/models/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite';

  late final Interpreter predictionInterpreter;
  late final IsolateInterpreter predictionIsolateInterpreter;
  late final Interpreter transferInterpreter;
  late final IsolateInterpreter transferIsolateInterpreter;

  final imagePicker = ImagePicker();
  String? imagePath;
  String? stylePath;
  Uint8List? imageResult;
  int? widthOrg;
  int? heightOrg;

  @override
  void initState() {
    super.initState();
    // Load model and labels from assets
    loadModels();
  }

  @override
  void dispose() {
    predictionIsolateInterpreter.close();
    transferIsolateInterpreter.close();
    super.dispose();
  }

  // Clean old results when press some take picture button
  void cleanResult() {
    imagePath = null;
    stylePath = null;
    imageResult = null;

    setState(() {});
  }

  // Load model
  Future<void> loadModels() async {
    final predictionOptions = InterpreterOptions();
    final transferOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      predictionOptions.addDelegate(XNNPackDelegate());
      transferOptions.addDelegate(XNNPackDelegate());
    }

    // Use GPU Delegate
    // doesn't work on emulator
    // if (Platform.isAndroid) {
    //    predictionOptions.addDelegate(GpuDelegateV2());
    //    transferOptions.addDelegate(GpuDelegateV2());
    // }

    // Use Metal Delegate
    if (Platform.isIOS) {
      predictionOptions.addDelegate(GpuDelegate());
      transferOptions.addDelegate(GpuDelegate());
    }

    // Load model from assets
    predictionInterpreter = await Interpreter.fromAsset(
      predictionModelPath,
      options: predictionOptions,
    );

    predictionIsolateInterpreter =
        await IsolateInterpreter.create(address: predictionInterpreter.address);

    transferInterpreter = await Interpreter.fromAsset(
      transferModelPath,
      options: transferOptions,
    );

    transferIsolateInterpreter =
        await IsolateInterpreter.create(address: transferInterpreter.address);

    setState(() {});

    log('Interpreters loaded successfully');

    log('\nPrediction Model: ');
    log('Input:');
    predictionInterpreter.getInputTensors().forEach(logTensorInfo);
    log('Output:');
    predictionInterpreter.getOutputTensors().forEach(logTensorInfo);

    log('\nTransfer Model: ');
    log('Input:');
    transferInterpreter.getInputTensors().forEach(logTensorInfo);
    log('Output:');
    transferInterpreter.getOutputTensors().forEach(logTensorInfo);
  }

  void logTensorInfo(Tensor tensor) {
    log('\t(name: ${tensor.name} shape: ${tensor.shape} type: ${tensor.type})');
  }

  List<List<List<num>>>? imageMatrix;

  // Process picked image
  Future<void> processImage() async {
    if (imagePath != null) {
      // Read image bytes from file
      final imageData = File(imagePath!).readAsBytesSync();

      // Decode image using package:image/image.dart (https://pub.dev/image)
      final image = img.decodeImage(imageData)!;

      setState(() {
        widthOrg = image.width;
        heightOrg = image.height;
      });

      // Resize image for model input (384, 384)
      final imageInput = img.copyResize(
        image,
        width: 384,
        height: 384,
      );

      imageMatrix = List.generate(
        imageInput.height,
        (y) => List.generate(
          imageInput.width,
          (x) {
            final pixel = imageInput.getPixel(x, y);
            return [pixel.r / 255, pixel.g / 255, pixel.b / 255];
          },
        ),
      );
    }
  }

  List<List<List<num>>>? styleMatrix;

  Future<void> processStyleImage() async {
    if (stylePath != null) {
      // Read image bytes from file
      final imageData = await rootBundle.load(stylePath!);

      // Decode image using package:image/image.dart (https://pub.dev/image)
      final image = img.decodeImage(imageData.buffer.asUint8List())!;

      // Resize image for model input (256, 256)
      final imageInput = img.copyResize(
        image,
        width: 256,
        height: 256,
      );

      styleMatrix = List.generate(
        imageInput.height,
        (y) => List.generate(
          imageInput.width,
          (x) {
            final pixel = imageInput.getPixel(x, y);
            return [pixel.r / 255, pixel.g / 255, pixel.b / 255];
          },
        ),
      );

      runInference();
    }
  }

  // Run inference
  Future<void> runInference() async {
    if (imageMatrix != null && styleMatrix != null) {
      // [1, 256, 256, 3]
      final predictionInput = [styleMatrix];

      // [1, 1, 1, 100]
      final predictionOutput = [
        [
          [List.filled(100, 0.0)]
        ]
      ];

      // Run prediction inference
      await predictionIsolateInterpreter.run(predictionInput, predictionOutput);

      // [1, 384, 384, 3]
      final transferOutput = [
        List.generate(
          384,
          (index) => List.filled(384, [0.0, 0.0, 0.0]),
        )
      ];

      final transferInput = [
        // image [1, 384, 384, 3]
        [imageMatrix],
        // style [1, 1, 1, 100]
        predictionOutput,
      ];

      // Run transfer inference
      await transferIsolateInterpreter.runForMultipleInputs(
        transferInput,
        {0: transferOutput},
      );

      // Get first output tensor
      final result = transferOutput.first;

      final buffer = Uint8List.fromList(result
          .expand(
            (col) => col.expand(
              (pixel) => pixel.map((e) => (e * 255).toInt()),
            ),
          )
          .toList());

      // Build image from matrix
      final image = img.Image.fromBytes(
        width: 384,
        height: 384,
        bytes: buffer.buffer,
        numChannels: 3,
      );

      // Encode image in jpeg format
      img.Image resized =
          img.copyResize(image, width: widthOrg, height: heightOrg);
      imageResult = img.encodeJpg(resized);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/tfl_logo.png'),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                  child: Stack(
                alignment: Alignment.center,
                children: [
                  if (imagePath != null)
                    StreamBuilder(
                        stream: transferIsolateInterpreter.stateChanges,
                        builder: (context, state) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: imageResult != null
                                    ? Image.memory(imageResult!)
                                    : Image.file(File(imagePath!)),
                              ),
                              if (stylePath != null)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Image.asset(
                                    stylePath!,
                                    height: 48,
                                  ),
                                ),
                              if (state.data == IsolateInterpreterState.loading)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          );
                        })
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Select an image from gallery or camera and a style image to apply style transfer',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                ],
              )),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    26,
                    (index) {
                      final path = 'assets/styles/style$index.jpg';
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            if (imagePath != null && imageMatrix != null) {
                              stylePath = path;
                              setState(() {});
                              processStyleImage();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              path,
                              height: 96,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // allow camera input only on mobile
                  if (Platform.isAndroid || Platform.isIOS)
                    IconButton(
                      onPressed: () async {
                        cleanResult();
                        final result = await imagePicker.pickImage(
                          source: ImageSource.camera,
                        );

                        imagePath = result?.path;
                        setState(() {});
                        processImage();
                      },
                      icon: const Icon(
                        Icons.camera,
                        size: 64,
                      ),
                    ),
                  IconButton(
                    onPressed: () async {
                      cleanResult();
                      final result = await imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );

                      imagePath = result?.path;
                      setState(() {});
                      processImage();
                    },
                    icon: const Icon(
                      Icons.photo,
                      size: 64,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
