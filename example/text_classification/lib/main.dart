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
import 'package:flutter/material.dart';
import 'package:tflite_flutter_plugin_example/classifier.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late TextEditingController _controller;
  late Classifier _classifier;
  late List<Widget> _children;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _classifier = Classifier();
    _children = [];
    _children.add(Container());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orangeAccent,
          title: const Text('Text classification'),
        ),
        body: Container(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: ListView.builder(
                itemCount: _children.length,
                itemBuilder: (_, index) {
                  return _children[index];
                },
              )),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.orangeAccent)),
                  child: Row(children: <Widget>[
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Write some text here'),
                        controller: _controller,
                      ),
                    ),
                    TextButton(
                      child: const Text('Classify'),
                      onPressed: () {
                        final text = _controller.text;
                        final prediction = _classifier.classify(text);
                        setState(() {
                          _children.add(Dismissible(
                            key: GlobalKey(),
                            onDismissed: (direction) {},
                            child: Card(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                color: prediction[1] > prediction[0]
                                    ? Colors.lightGreen
                                    : Colors.redAccent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Input: $text",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Text("Output:"),
                                    Text("   Positive: ${prediction[1]}"),
                                    Text("   Negative: ${prediction[0]}"),
                                  ],
                                ),
                              ),
                            ),
                          ));
                          _controller.clear();
                        });
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
