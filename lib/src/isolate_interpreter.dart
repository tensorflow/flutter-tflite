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

import 'dart:async';
import 'dart:isolate';

import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateInterpreter {
  IsolateInterpreter({
    required this.address,
    this.debugName = 'TfLiteInterpreterIsolate',
  }) {
    _init();
  }

  final int address;
  final String debugName;

  final ReceivePort _receivePort = ReceivePort();
  late final SendPort _sendPort;
  late final Isolate _isolate;

  final StreamController<IsolateInterpreterState> _stateChanges =
      StreamController.broadcast();
  late final StreamSubscription _stateSubscription;
  Stream<IsolateInterpreterState> get stateChanges => _stateChanges.stream;
  IsolateInterpreterState __state = IsolateInterpreterState.idle;
  IsolateInterpreterState get state => __state;
  set _state(IsolateInterpreterState value) {
    __state = value;
    if (!_stateChanges.isClosed) {
      _stateChanges.add(__state);
    }
  }

  Future<void> _init() async {
    _isolate = await Isolate.spawn(
      _mainIsolate,
      _receivePort.sendPort,
      debugName: debugName,
    );

    _stateSubscription = _receivePort.listen((state) {
      if (state is SendPort) {
        _sendPort = state;
      }

      if (state is IsolateInterpreterState) {
        _state = state;
      }
    });
  }

  static Future<void> _mainIsolate(SendPort sendPort) async {
    final port = ReceivePort();

    sendPort.send(port.sendPort);

    await for (final _IsolateInterpreterData data in port) {
      final interpreter = Interpreter.fromAddress(data.address);
      sendPort.send(IsolateInterpreterState.loading);
      interpreter.runInference(data.inputs);
      sendPort.send(IsolateInterpreterState.idle);
    }
  }

  /// Run for single input and output
  Future<void> run(Object input, Object output) {
    var map = <int, Object>{};
    map[0] = output;

    return runForMultipleInputs([input], map);
  }

  /// Run for multiple inputs and outputs
  Future<void> runForMultipleInputs(
    List<Object> inputs,
    Map<int, Object> outputs,
  ) async {
    if (state == IsolateInterpreterState.loading) return;
    _state = IsolateInterpreterState.loading;

    final data = _IsolateInterpreterData(
      address: address,
      inputs: inputs,
    );

    _sendPort.send(data);
    await _wait();

    final interpreter = Interpreter.fromAddress(address);
    final outputTensors = interpreter.getOutputTensors();
    for (var i = 0; i < outputTensors.length; i++) {
      outputTensors[i].copyTo(outputs[i]!);
    }
  }

  Future<void> _wait() async {
    if (state == IsolateInterpreterState.loading) {
      await for (final state in stateChanges) {
        if (state == IsolateInterpreterState.idle) break;
      }
    }
  }

  Future<void> close() async {
    await _stateSubscription.cancel();
    await _stateChanges.close();
    _isolate.kill();
  }
}

enum IsolateInterpreterState {
  idle,
  loading,
}

class _IsolateInterpreterData {
  _IsolateInterpreterData({
    required this.address,
    required this.inputs,
  });

  final int address;
  final List<Object> inputs;
}
