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

/// `IsolateInterpreter` allows for the execution of TensorFlow models within an isolate.
class IsolateInterpreter {
  // Private constructor for the interpreter.
  IsolateInterpreter._({
    required this.address,
    required this.debugName,
  });

  // Factory method to create an instance of the IsolateInterpreter.
  static Future<IsolateInterpreter> create({
    required int address,
    String debugName = 'TfLiteInterpreterIsolate',
  }) async {
    final interpreter = IsolateInterpreter._(
      address: address,
      debugName: debugName,
    );

    await interpreter._init(); // Initialize the instance.

    return interpreter;
  }

  final int address;
  final String debugName;

  final ReceivePort _receivePort = ReceivePort();
  late final SendPort _sendPort;
  late final Isolate _isolate;

  // Controller to handle state changes.
  final StreamController<IsolateInterpreterState> _stateChanges =
      StreamController.broadcast();
  late final StreamSubscription _stateSubscription;
  Stream<IsolateInterpreterState> get stateChanges => _stateChanges.stream;
  IsolateInterpreterState __state = IsolateInterpreterState.idle;
  IsolateInterpreterState get state => __state;

  // Setter to handle state changes.
  set _state(IsolateInterpreterState value) {
    __state = value;
    if (!_stateChanges.isClosed) {
      _stateChanges.add(__state);
    }
  }

  // Initialize the isolate and set up communication.
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

  // Main function for the spawned isolate.
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

  /// Run TensorFlow model for single input and output.
  Future<void> run(Object input, Object output) {
    var map = <int, Object>{};
    map[0] = output;

    return runForMultipleInputs([input], map);
  }

  /// Run TensorFlow model for multiple inputs and outputs.
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

  // Wait for the state to change to idle.
  Future<void> _wait() async {
    if (state == IsolateInterpreterState.loading) {
      await for (final state in stateChanges) {
        if (state == IsolateInterpreterState.idle) break;
      }
    }
  }

  // Close resources and terminate the isolate.
  Future<void> close() async {
    await _stateSubscription.cancel();
    await _stateChanges.close();
    _isolate.kill();
  }
}

// Represents the state of the IsolateInterpreter.
enum IsolateInterpreterState {
  idle,
  loading,
}

// Helper class to encapsulate data for the isolate.
class _IsolateInterpreterData {
  _IsolateInterpreterData({
    required this.address,
    required this.inputs,
  });

  final int address;
  final List<Object> inputs;
}
