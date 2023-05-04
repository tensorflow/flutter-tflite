 <p align="center">
    <br>
    <img src="https://github.com/am15h/tflite_flutter_plugin/raw/update_readme/docs/tflite_flutter_cover.png"/>
    </br>
</p>
<p align="center">
 
   <a href="https://flutter.dev">
     <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter"
       alt="Platform" />
   </a>
   <a href="https://pub.dartlang.org/packages/tflite_flutter">
     <img src="https://img.shields.io/pub/v/tflite_flutter.svg"
       alt="Pub Package" />
   </a>
    <a href="https://pub.dev/documentation/tflite_flutter/latest/tflite_flutter/tflite_flutter-library.html">
        <img alt="Docs" src="https://readthedocs.org/projects/hubdb/badge/?version=latest">
    </a>
    <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"></a>


</a>
</p>

## Announcement

Update: 26 April, 2023

This repo is a TensorFlow managed fork of the [tflite_flutter_plugin](https://github.com/am15h/tflite_flutter_plugin) project by the amazing Amish Garg. The goal of this project is to support our Flutter community in creating machine-learning backed apps with the TensorFlow Lite framework.

This project is currently a work-in-progress as we update it to create a working plugin that meets the latest and greatest Flutter and TensorFlow Lite standards. That said, *pull requests and contributions are more than welcome* and will be reviewed by TensorFlow or Flutter team members. We thank you for your understanding as we make progress on this update.

Feel free to reach out to me with questions until then.

Thanks!

- ptruiz@google.com

## Overview

TensorFlow Lite Flutter plugin provides a flexible and fast solution for accessing TensorFlow Lite interpreter and performing inference. The API is similar to the TFLite Java and Swift APIs. It directly binds to TFLite C API making it efficient (low-latency). Offers acceleration support using NNAPI, GPU delegates on Android, Metal and CoreML delegates on iOS, and XNNPack delegate on Desktop platforms.


## Key Features

* Multi-platform Support for Android and iOS
* Flexibility to use any TFLite Model.
* Acceleration using multi-threading.
* Similar structure as TensorFlow Lite Java API.
* Inference speeds close to native Android Apps built using the Java API.
* Run inference in different isolates to prevent jank in UI thread.


## (Important) Initial setup : Add dynamic libraries to your app

### Android

Copy the folders from https://github.com/tensorflow/flutter-tflite/tree/main/releases/download/android into your project's /android/app/src/main/jniLibs directory.

### iOS

 TODO: Sample now works, info soon

Note: TFLite may not work in the iOS simulator. It's recommended that you test with a physical device.

## TFLite Flutter Helper Library

The helper library has been deprecated. New development underway for a replacement at https://github.com/google/flutter-mediapipe

## Import

```dart
import 'package:tflite_flutter/tflite_flutter.dart';
```

## Usage instructions

### Creating the Interpreter

* **From asset**

    Place `your_model.tflite` in `assets` directory. Make sure to include assets in `pubspec.yaml`.

    ```dart
    final interpreter = await tfl.Interpreter.fromAsset('your_model.tflite');
    ```

Refer to the documentation for info on creating interpreter from buffer or file.

### Performing inference

* **For single input and output**

    Use `void run(Object input, Object output)`.
    ```dart
    // For ex: if input tensor shape [1,5] and type is float32
    var input = [[1.23, 6.54, 7.81, 3.21, 2.22]];

    // if output tensor shape [1,2] and type is float32
    var output = List.filled(1*2, 0).reshape([1,2]);

    // inference
    interpreter.run(input, output);

    // print the output
    print(output);
    ```
  
* **For multiple inputs and outputs**

    Use `void runForMultipleInputs(List<Object> inputs, Map<int, Object> outputs)`.

    ```dart
    var input0 = [1.23];  
    var input1 = [2.43];  

    // input: List<Object>
    var inputs = [input0, input1, input0, input1];  

    var output0 = List<double>.filled(1, 0);  
    var output1 = List<double>.filled(1, 0);

    // output: Map<int, Object>
    var outputs = {0: output0, 1: output1};

    // inference  
    interpreter.runForMultipleInputs(inputs, outputs);

    // print outputs
    print(outputs)
    ```

### Closing the interpreter

```dart
interpreter.close();
```

Refer [Tests](https://github.com/tensorflow/flutter-tflite/blob/main/example/integration_test/tflite_flutter_test.dart) to see more example code for each method.
