import 'dart:collection';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'feature.dart';
import 'feature_convert.dart';
import 'qa_answer.dart';

class QaClient {
  static String TAG = "BertDemo";

  static int MAX_ANS_LEN = 32;
  static int MAX_QUERY_LEN = 64;
  static int MAX_SEQ_LEN = 384;
  static bool DO_LOWER_CASE = true;
  static int PREDICT_ANS_NUM = 5;
  static String IDS_TENSOR_NAME = "ids";
  static String MASK_TENSOR_NAME = "mask";
  static String SEGMENT_IDS_TENSOR_NAME = "segment_ids";
  static String END_LOGITS_TENSOR_NAME = "end_logits";
  static String START_LOGITS_TENSOR_NAME = "start_logits";

  // Need to shift 1 for outputs ([CLS]).
  static final int OUTPUT_OFFSET = 1;

  Map<String, int> dic = {};
  late FeatureConverter featureConverter;
  static const _modelPath = "assets/mobilebert.tflite";
  static const _vocab = "assets/vocab.txt";
  late Interpreter _interpreter;

  Future<void> initQaClient() async {
    await loadVocab();
    await loadModel();
  }

  Future<void> loadModel() async {
    final options = InterpreterOptions();
    // Load model from assets
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    featureConverter =
        FeatureConverter(dic, DO_LOWER_CASE, MAX_QUERY_LEN, MAX_SEQ_LEN);
    log('Interpreter loaded successfully');
  }

  Future<void> loadVocab() async {
    String vocabString = await rootBundle.loadString(_vocab);
    List<String> vocabs = vocabString.split("\n");
    Map<String, int> resultMap = {};
    for (int i = 0; i < vocabs.length; i++) {
      resultMap[vocabs[i]] = i;
    }
    dic = resultMap;
  }

  Future<List<QaAnswer>> runInference(String query, String content) async {
    Feature feature = featureConverter.convert(query, content);

    List<int> inputIds = List.filled(MAX_SEQ_LEN, 0, growable: true);
    List<int> inputMask = List.filled(MAX_SEQ_LEN, 0, growable: true);
    List<int> segmentIds = List.filled(MAX_SEQ_LEN, 0, growable: true);
    List<double> startLogits = List.filled(MAX_SEQ_LEN, 0.0, growable: true);
    List<double> endLogits = List.filled(MAX_SEQ_LEN, 0.0, growable: true);

    for (int j = 0; j < MAX_SEQ_LEN; j++) {
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

    List<QaAnswer> answers = getBestAnswers(
        (outputs[startLogitsIdx] as List<List<double>>)[0],
        (outputs[endLogitsIdx] as List<List<double>>)[0],
        feature);
    return answers;
  }

  List<QaAnswer> getBestAnswers(
      List<double> startLogits, List<double> endLogits, Feature feature) {
    // Model uses the closed interval [start, end] for indices.
    List<int> startIndexes = getBestIndex(startLogits);
    List<int> endIndexes = getBestIndex(endLogits);

    List<Pos> origResults = [];
    for (int start in startIndexes) {
      for (int end in endIndexes) {
        if (!feature.tokenToOrigMap.containsKey(start + OUTPUT_OFFSET)) {
          continue;
        }
        if (!feature.tokenToOrigMap.containsKey(end + OUTPUT_OFFSET)) {
          continue;
        }
        if (end < start) {
          continue;
        }
        int length = end - start + 1;
        if (length > MAX_ANS_LEN) {
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
      if (i >= PREDICT_ANS_NUM) {
        break;
      }

      String convertedText;
      if (origResults[i].start > 0) {
        convertedText =
            convertBack(feature, origResults[i].start, origResults[i].end);
      } else {
        convertedText = "";
      }
      QaAnswer ans = QaAnswer(pos: origResults[i], text: convertedText);
      answers.add(ans);
    }
    return answers;
  }

  List<int> getBestIndex(List<double> logits) {
    List<Pos> tmpList = [];
    for (int i = 0; i < MAX_SEQ_LEN; i++) {
      tmpList.add(Pos(start: i, end: i, logit: logits[i]));
    }
    tmpList.sort();

    List<int> indexes = List.filled(PREDICT_ANS_NUM, 0);
    for (int i = 0; i < PREDICT_ANS_NUM; i++) {
      indexes[i] = tmpList[i].start;
    }
    return indexes;
  }

  static String convertBack(Feature feature, int start, int end) {
    // Shifted index is: index of logits + offset.
    int shiftedStart = start + OUTPUT_OFFSET;
    int shiftedEnd = end + OUTPUT_OFFSET;
    int startIndex = feature.tokenToOrigMap[shiftedStart]!;
    int endIndex = feature.tokenToOrigMap[shiftedEnd]!;
    // end + 1 for the closed interval.
    String ans = feature.origTokens.sublist(startIndex, endIndex + 1).join(" ");
    return ans;
  }
}
