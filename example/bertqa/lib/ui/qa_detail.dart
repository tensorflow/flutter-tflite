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

import 'package:bertqa/ml/qa_answer.dart';
import 'package:bertqa/ml/qa_client.dart';
import 'package:flutter/material.dart';

class QaDetail extends StatefulWidget {
  const QaDetail(
      {super.key,
      required this.title,
      required this.content,
      required this.questions});

  final String title;
  final String content;
  final List<String> questions;

  @override
  State<QaDetail> createState() => _QaDetailState();
}

class _QaDetailState extends State<QaDetail> {
  late QaClient _qaClient;
  final TextEditingController _controller = TextEditingController();
  String _currentQuestion = "";
  QaAnswer? _qaAnswer;
  int _answerIndex = 0;

  @override
  void initState() {
    _qaClient = QaClient();
    _qaClient.initQaClient();
    super.initState();
  }

  void _updateQuestion(int questionIndex) {
    String question = widget.questions[questionIndex];
    setState(() {
      _currentQuestion = question;
      _controller.text = _currentQuestion;
    });
  }

  Future<void> _answerQuestion() async {
    if (_currentQuestion.isEmpty) {
      return;
    }

    // Append question mark '?' if not ended with '?'.
    // This aligns with question format that trains the model.
    String trimQuestion = _currentQuestion.trim();
    if (!trimQuestion.endsWith("?")) {
      trimQuestion += "?";
    }
    List<QaAnswer> answers =
        await _qaClient.runInference(trimQuestion, widget.content);
    // Highlight the answer here
    _highlightAnswer(answers.first);
  }

  void _highlightAnswer(QaAnswer answer) {
    setState(() {
      _qaAnswer = answer;
      _answerIndex = widget.content.indexOf(_qaAnswer!.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFA800),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "TFL Question and Answer",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _qaAnswer == null
                      ? Text(
                          widget.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : RichText(
                          text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                if (_answerIndex > 0)
                                  TextSpan(
                                      text: widget.content
                                          .substring(0, _answerIndex)),
                                TextSpan(
                                    style: TextStyle(
                                        background: Paint()
                                          ..color = Colors.yellow),
                                    text: widget.content.substring(_answerIndex,
                                        _answerIndex + _qaAnswer!.text.length)),
                                if ((_answerIndex + _qaAnswer!.text.length) <
                                    widget.content.length)
                                  TextSpan(
                                      text: widget.content.substring(
                                          _answerIndex + _qaAnswer!.text.length,
                                          widget.content.length))
                              ]),
                        ))),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
            // color: Colors.white,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("You may want to ask?"),
                ),
                SizedBox(
                    height: 48,
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(
                        indent: 16,
                      ),
                      itemCount: widget.questions.length,
                      itemBuilder: (context, index) {
                        return FilterChip(
                            label: Text(widget.questions[index]),
                            onSelected: (bool selected) {
                              _updateQuestion(index);
                            });
                      },
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            labelText: "Text query"),
                        onChanged: (text) {
                          setState(() {
                            _currentQuestion = text;
                          });
                        },
                      ),
                    ),
                    const Divider(
                      endIndent: 16,
                    ),
                    ElevatedButton(
                      onPressed: _currentQuestion.isNotEmpty
                          ? () {
                              _answerQuestion();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey,
                          backgroundColor: const Color(0xFFFFA800)),
                      child: const Icon(
                        Icons.east,
                        color: Colors.white,
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
