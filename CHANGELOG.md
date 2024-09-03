## 0.11.0 (September 3, 2024)
* FFI update, Dart/Flutter version updates

## 0.10.2 (September 27, 2023)
* MacOS desktop support added!
* Additional samples added
* Various bug fixes

## 0.10.0 (May 22, 2023)
* Use ffi for binding to iOS dependencies. Use the ios/tflite_flutter.podspec file to specify tensorflow lite library version. Dependencies are automatically downloaded without user intervention (no need for releases/download folder)
* Use ffi for binding with Android dependencies. Use the android/build.gradle file to specify tensorflow lite library version. Dependencies are automatically downloaded without user intervention (no need for releases/download folder)
* Use ffigen to generate the binding code in dart
* Enable delegates in text_classification example
* Add conversion for tensors of type uint8
* Add image classification example using mobilenet
* Add super resolution example using esrgan
* Add style transfer example
* IsolateInterpreter to run inference in an isolate. Related to Use isolates to run inference #52
* Support for melos added
* Text classification example fixed

## 0.9.0 (Jun 28, 2021)
* Support for Windows, Mac and Linux platforms.
* Improved gpu delegate support and bug fixes.
* Support for CoreML and XnnPack delegates.

## 0.8.0 (Apr 21, 2021)
* Null-safety major bug fix in tensor.dart
* Expose byte-object interconversion APIs

## 0.7.0 (Apr 21, 2021)
* Stable null-safety support

## 0.6.0 (Feb 26, 2021)
* Update to Dart 2.12 and package:ffi 1.0.0.

## 0.5.0 (Jul 17, 2020)
* Expose interpreter's address
* Create interpreter by address.

## 0.4.2 (Jul 6, 2020)
* Optimize getTensors and getTensor by Index
* Update readme

## 0.4.1 (Jun 23, 2020)
* Bug fix, output values copy to bytebuffer

## 0.4.0 (Jun 18, 2020)
* run supports UintList8 and ByteBuffer objects
* Bug fix, resize input tensor
* Improved efficiency

## 0.3.0
* New features
    * multi-dimensional reshape with type
* Bug fixes
    * extension flatten on List fixed.
    * error on passing not dynamic type list to interpreter output fixed

## 0.2.0
* Direct conversion support for more TfLiteTypes
* int16, float16, int8, int64
* Pre-built tf 2.2.0 stable binaries

## 0.1.3
* update usage instructions

## 0.1.2
* fixed analysis issues to improve score

## 0.1.1
* fixed warnings
* longer package description

## 0.1.0

* TfLite dart API
