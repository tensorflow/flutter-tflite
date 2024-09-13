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
  static const modelPath = 'assets/models/esrgan-tf2.tflite';

  late final Interpreter interpreter;
  late final List<String> labels;

  Tensor? inputTensor;
  Tensor? outputTensor;

  String? imagePath;
  Uint8List? imageResult;

  @override
  void initState() {
    super.initState();
    // Load model and labels from assets
    loadModel();
  }

  // Clean old results when press some take picture button
  void cleanResult() {
    imagePath = null;
    imageResult = null;

    setState(() {});
  }

  // Load model
  Future<void> loadModel() async {
    final options = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    // Use GPU Delegate
    // doesn't work on emulator
    // if (Platform.isAndroid) {
    //   options.addDelegate(GpuDelegateV2());
    // }

    // Use Metal Delegate
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelPath, options: options);
    // Get tensor input shape [1, 50, 50, 3]
    inputTensor = interpreter.getInputTensors().first;
    // Get tensor output shape [1, 200, 200, 3]
    outputTensor = interpreter.getOutputTensors().first;
    setState(() {});

    log('Interpreter loaded successfully');
  }

  // Process picked image
  Future<void> processImage() async {
    if (imagePath != null) {
      // Read image bytes from file
      final imageData = await rootBundle.load(imagePath!);

      // Decode image using package:image/image.dart (https://pub.dev/image)
      final image = img.decodeImage(imageData.buffer.asUint8List())!;

      // Get image matrix representation [50, 50, 3]
      final imageMatrix = List.generate(
        image.height,
        (y) => List.generate(
          image.width,
          (x) {
            final pixel = image.getPixel(x, y);
            return [pixel.r, pixel.g, pixel.b];
          },
        ),
      );

      // Run model inference
      runInference(imageMatrix);
    }
  }

  // Run inference
  Future<void> runInference(
    List<List<List<num>>> imageMatrix,
  ) async {
    // Set tensor input [1, 50, 50, 3]
    final input = [imageMatrix];

    // Set tensor output [1, 200, 200, 3]
    final output = [
      List.generate(
        200,
        (index) => List.filled(200, [0.0, 0.0, 0.0]),
      )
    ];

    // Run inference
    interpreter.run(input, output);

    // Get first output tensor
    final result = output.first;

    final buffer = Uint8List.fromList(result
        .expand(
          (col) => col.expand(
            (pixel) => pixel.map((e) => e.toInt()),
          ),
        )
        .toList());

    // Build image from matrix
    final image = img.Image.fromBytes(
      width: 200,
      height: 200,
      bytes: buffer.buffer,
      numChannels: 3,
    );

    // Encode image in jpeg format
    imageResult = img.encodeJpg(image);

    setState(() {});
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
                  if (imageResult != null)
                    Image.memory(imageResult!)
                  else
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Select an image example for super resolution from 50x50 to 200x200',
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(),
                            // Show model information
                            Text(
                              'Input: (shape: ${inputTensor?.shape} type: ${inputTensor?.type})',
                            ),
                            Text(
                              'Output: (shape: ${outputTensor?.shape} type: ${outputTensor?.type})',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )),
              Column(
                children: [
                  const Text('50 x 50 images'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        3,
                        (index) {
                          final path = 'assets/lr/lr-${index + 1}.jpg';
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                cleanResult();
                                imagePath = path;
                                processImage();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(path),
                              ),
                            ),
                          );
                        },
                      ),
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
