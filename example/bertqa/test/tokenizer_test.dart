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

import 'dart:io';

import 'package:bertqa/ml/feature_convert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("CharCheckerTest", () {
    test("Whitespace for bert", () {
      expect(CharChecker.isWhitespaceForBert(" "), true);
      expect(CharChecker.isWhitespaceForBert("\n"), true);
      expect(CharChecker.isWhitespaceForBert("\t"), true);
      expect(CharChecker.isWhitespaceForBert("\r"), true);
      expect(CharChecker.isWhitespaceForBert("a"), false);
    });
    test("Invalid for bert", () {
      // unknown char
      expect(CharChecker.isInvalid('\uFFFD'), true);
      expect(CharChecker.isInvalid('\u0000'), true);
      expect(CharChecker.isInvalid('a'), false);
    });
    test("Control chart", () {
      expect(CharChecker.isControlForBert('\b'), true);
      expect(CharChecker.isControlForBert(''), true);
      expect(CharChecker.isControlForBert('a'), false);
    });
    test("Punctuation char", () {
      expect(CharChecker.isPunctuationForBert('-'), true);
      expect(CharChecker.isPunctuationForBert('['), true);
      expect(CharChecker.isPunctuationForBert(','), true);
      expect(CharChecker.isPunctuationForBert('a'), false);
    });
  });

  group("Basic token", () {
    test("Clean text", () {
      String testExample = "This is an\rexample.\n";
      String testChar = String.fromCharCode(0);
      String unknownChar = String.fromCharCode(0xfffd);

      expect(BasicTokenizer.cleanText(testExample), "This is an example. ");
      expect(BasicTokenizer.cleanText(testExample + testChar),
          "This is an example. ");
      expect(BasicTokenizer.cleanText(testExample + unknownChar),
          "This is an example. ");
    });

    test("Run split on punc", () {
      expect(BasicTokenizer.runSplitOnPunc("Hi,there."),
          ["Hi", ",", "there", "."]);
      expect(BasicTokenizer.runSplitOnPunc("I'm \"Spider-Man\""),
          ["I", "'", "m ", "\"", "Spider", "-", "Man", "\""]);
    });

    test("WhitespaceTokenize", () {
      expect(BasicTokenizer.whitespaceTokenize("Hi , This is an example. "),
          ["Hi", ",", "This", "is", "an", "example."]);
    });

    test("Tokenize with lowercase test", () {
      BasicTokenizer basicTokenizer = BasicTokenizer(doLowerCase: true);
      expect(basicTokenizer.tokenize("  Hi, This\tis an example.\n"),
          ["hi", ",", "this", "is", "an", "example", "."]);
      expect(basicTokenizer.tokenize("Hello,How are you?"),
          ["hello", ",", "how", "are", "you", "?"]);
    });
  });

  group("WordpieceTokenizer", () {
    test('tokenize', () async {
      // load vocal
      File file = File('assets/vocab.txt');
      List<String> dic = await file.readAsLines();
      Map<String, int> resultMap = {};
      for (int i = 0; i < dic.length; i++) {
        resultMap[dic[i]] = i;
      }

      // test
      WordpieceTokenizer wordpieceTokenizer =
          WordpieceTokenizer(dic: resultMap);

      expect(
          wordpieceTokenizer.tokenize("meaningfully"), ["meaningful", "##ly"]);
      expect(wordpieceTokenizer.tokenize("teacher"), ["teacher"]);
    });
  });

  group("Full token", () {
    File file = File('assets/vocab.txt');

    test("tokenize", () async {
      List<String> dic = await file.readAsLines();
      Map<String, int> resultMap = {};
      for (int i = 0; i < dic.length; i++) {
        resultMap[dic[i]] = i;
      }
      FullTokenizer fullTokenizer = FullTokenizer(resultMap, true);
      expect(fullTokenizer.tokenize("Good morning, I'm your teacher.\n"),
          ["good", "morning", ",", "i", "'", "m", "your", "teacher", "."]);
      expect(fullTokenizer.tokenize(""), []);
    });

    test("convertTokensToIdsTest", () async {
      List<String> dic = await file.readAsLines();
      Map<String, int> resultMap = {};
      for (int i = 0; i < dic.length; i++) {
        resultMap[dic[i]] = i;
      }
      FullTokenizer fullTokenizer = FullTokenizer(resultMap, true);
      expect(
          fullTokenizer.convertTokensToIds(
              ["good", "morning", ",", "i", "'", "m", "your", "teacher", "."]),
          [2204, 2851, 1010, 1045, 1005, 1049, 2115, 3836, 1012]);
    });
  });
}
