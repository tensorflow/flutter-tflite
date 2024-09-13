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

import 'dart:collection';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'feature.dart';
import 'feature_convert.dart';
import 'qa_answer.dart';

class QaClient {
  static String tag = "BertDemo";

  static int maxAnsLen = 32;
  static int maxQueryLen = 64;
  static int maxSeqLen = 384;
  static bool doLowerCase = true;
  static int predictAnsNum = 5;
  static String idsTensorName = "ids";
  static String maskTensorName = "mask";
  static String segmentIdsTensorName = "segment_ids";
  static String endLogitsTensorName = "end_logits";
  static String startLogitsTensorName = "start_logits";

  // Need to shift 1 for outputs ([CLS]).
  static const int outputOffset = 1;

  Map<String, int> dic = {};
  late FeatureConverter featureConverter;
  static const _modelPath = "assets/mobilebert.tflite";
  static const _vocab = "assets/vocab.txt";
  late Interpreter _interpreter;

  Future<void> initQaClient() async {
    await _loadVocab();
    await _loadModel();
  }

  Future<void> _loadModel() async {
    final options = InterpreterOptions();
    // Load model from assets
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    featureConverter =
        FeatureConverter(dic, doLowerCase, maxQueryLen, maxSeqLen);
    log('Interpreter loaded successfully');
  }

  Future<void> _loadVocab() async {
    String vocabString = await rootBundle.loadString(_vocab);
    List<String> vocabs = vocabString.split("\n");
    Map<String, int> resultMap = {};
    for (int i = 0; i < vocabs.length; i++) {
      resultMap[vocabs[i]] = i;
    }
    dic = resultMap;
  }

  /// Input: Original content and query for the QA task. Later converted to Feature by
  /// FeatureConverter. Output: A String[] array of answers and a float[] array of corresponding
  /// logits.
  Future<List<QaAnswer>> runInference(String query, String content) async {
    Feature feature = featureConverter.convert(query, content);

    List<int> inputIds = List.filled(maxSeqLen, 0, growable: true);
    List<int> inputMask = List.filled(maxSeqLen, 0, growable: true);
    List<int> segmentIds = List.filled(maxSeqLen, 0, growable: true);
    List<double> startLogits = List.filled(maxSeqLen, 0.0, growable: true);
    List<double> endLogits = List.filled(maxSeqLen, 0.0, growable: true);

    for (int j = 0; j < maxSeqLen; j++) {
      inputIds[j] = feature.inputIds[j];
      inputMask[j] = feature.inputMask[j];
      segmentIds[j] = feature.segmentIds[j];
    }

    List<Object> inputs = List.filled(3, List.empty(), growable: true);
    inputs[0] = [inputIds];
    inputs[1] = [inputMask];
    inputs[2] = [segmentIds];

    Map<int, Object> outputs = HashMap();
    int endLogitsIdx = 0;
    int startLogitsIdx = 1;

    outputs[endLogitsIdx] = [endLogits];
    outputs[startLogitsIdx] = [startLogits];

    _interpreter.runForMultipleInputs(inputs, outputs);

    List<QaAnswer> answers = _getBestAnswers(
        (outputs[startLogitsIdx] as List<List<double>>)[0],
        (outputs[endLogitsIdx] as List<List<double>>)[0],
        feature);
    return answers;
  }

  /// Find the Best N answers & logits from the logits array and input feature.
  List<QaAnswer> _getBestAnswers(
      List<double> startLogits, List<double> endLogits, Feature feature) {
    // Model uses the closed interval [start, end] for indices.
    List<int> startIndexes = _getBestIndex(startLogits);
    List<int> endIndexes = _getBestIndex(endLogits);

    List<Pos> origResults = [];
    for (int start in startIndexes) {
      for (int end in endIndexes) {
        if (!feature.tokenToOrigMap.containsKey(start + outputOffset)) {
          continue;
        }
        if (!feature.tokenToOrigMap.containsKey(end + outputOffset)) {
          continue;
        }
        if (end < start) {
          continue;
        }
        int length = end - start + 1;
        if (length > maxAnsLen) {
          continue;
        }
        origResults.add(Pos(
            start: start,
            end: end,
            logit: startLogits[start] + endLogits[end]));
      }
    }
    origResults.sort();

    List<QaAnswer> answers = [];
    for (int i = 0; i < origResults.length; i++) {
      if (i >= predictAnsNum) {
        break;
      }

      String convertedText;
      if (origResults[i].start > 0) {
        convertedText =
            _convertBack(feature, origResults[i].start, origResults[i].end);
      } else {
        convertedText = "";
      }
      QaAnswer ans = QaAnswer(pos: origResults[i], text: convertedText);
      answers.add(ans);
    }
    return answers;
  }

  /// Get the n-best logins from a list of all the logits.
  List<int> _getBestIndex(List<double> logits) {
    List<Pos> tmpList = [];
    for (int i = 0; i < maxSeqLen; i++) {
      tmpList.add(Pos(start: i, end: i, logit: logits[i]));
    }
    tmpList.sort();

    List<int> indexes = List.filled(predictAnsNum, 0);
    for (int i = 0; i < predictAnsNum; i++) {
      indexes[i] = tmpList[i].start;
    }
    return indexes;
  }

  /// Convert the answer back to original text form.
  static String _convertBack(Feature feature, int start, int end) {
    // Shifted index is: index of logits + offset.
    int shiftedStart = start + outputOffset;
    int shiftedEnd = end + outputOffset;
    int startIndex = feature.tokenToOrigMap[shiftedStart]!;
    int endIndex = feature.tokenToOrigMap[shiftedEnd]!;
    // end + 1 for the closed interval.
    String ans = feature.origTokens.sublist(startIndex, endIndex + 1).join(" ");
    return ans;
  }
}
