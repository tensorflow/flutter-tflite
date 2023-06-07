import 'dart:io';

import 'package:tflite_flutter/src/bindings/bindings_flex.dart';
import 'package:tflite_flutter/src/delegates/flex_delegate_my.dart';

import '../../tflite_flutter.dart';

/// Author: cpoohee
/// https://github.com/cpoohee/tflite_flutter_plugin
void optionsAddFlexDelegateAndroid(InterpreterOptions options) {
  if (Platform.isAndroid) {
    tfLite_flex_initTensorflow();
    options.addDelegate(Flex_Delegate());
  }
}