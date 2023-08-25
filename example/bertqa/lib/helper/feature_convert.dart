import 'dart:collection';

import 'feature.dart';

class FeatureConverter {
  late FullTokenizer tokenizer;
  late int maxQueryLen;
  late int maxSeqLen;

  FeatureConverter(Map<String, int> inputDic, bool doLowerCase,
      this.maxQueryLen, this.maxSeqLen) {
    tokenizer = FullTokenizer(inputDic, doLowerCase);
  }

  Feature convert(String query, String context) {
    List<String> queryTokens = tokenizer.tokenize(query);
    if (queryTokens.length > maxQueryLen) {
      queryTokens = queryTokens.sublist(0, maxQueryLen);
    }

    List<String> origTokens = context.trim().split(RegExp(r'\s+'));
    List<int> tokenToOrigIndex = [];
    List<String> allDocTokens = [];
    for (int i = 0; i < origTokens.length; i++) {
      String token = origTokens[i];
      List<String> subTokens = tokenizer.tokenize(token);
      for (String subToken in subTokens) {
        tokenToOrigIndex.add(i);
        allDocTokens.add(subToken);
      }
    }

    // -3 accounts for [CLS], [SEP] and [SEP].
    int maxContextLen = maxSeqLen - queryTokens.length - 3;
    if (allDocTokens.length > maxContextLen) {
      allDocTokens = allDocTokens.sublist(0, maxContextLen);
    }

    List<String> tokens = [];
    List<int> segmentIds = [];

    // Map token index to original index (in feature.origTokens).
    HashMap<int, int> tokenToOrigMap = HashMap();

    // Start of generating the features.
    tokens.add("[CLS]");
    segmentIds.add(0);

    // For query input.
    for (String queryToken in queryTokens) {
      tokens.add(queryToken);
      segmentIds.add(0);
    }

    // For Separation.
    tokens.add("[SEP]");
    segmentIds.add(0);

    // For Text Input.
    for (int i = 0; i < allDocTokens.length; i++) {
      String docToken = allDocTokens[i];
      tokens.add(docToken);
      segmentIds.add(1);
      tokenToOrigMap[tokens.length] = tokenToOrigIndex[i];
    }

    // For ending mark.
    tokens.add("[SEP]");
    segmentIds.add(1);

    List<int> inputIds = tokenizer.convertTokensToIds(tokens);
    List<int> inputMask = List.filled(inputIds.length, 1, growable: true);

    while (inputIds.length < maxSeqLen) {
      inputIds.add(0);
      inputMask.add(0);
      segmentIds.add(0);
    }
    return Feature(
        inputIds: inputIds,
        inputMask: inputMask,
        segmentIds: segmentIds,
        origTokens: origTokens,
        tokenToOrigMap: tokenToOrigMap);
  }
}

class FullTokenizer {
  late BasicTokenizer basicTokenizer;
  late WordpieceTokenizer wordpieceTokenizer;
  late Map<String, int> dic;

  FullTokenizer(Map<String, int> inputDic, bool doLowerCase) {
    dic = inputDic;
    basicTokenizer = BasicTokenizer(doLowerCase: doLowerCase);
    wordpieceTokenizer = WordpieceTokenizer(dic: inputDic);
  }

  List<String> tokenize(String text) {
    List<String> splitTokens = [];
    for (var token in basicTokenizer.tokenize(text)) {
      splitTokens.addAll(wordpieceTokenizer.tokenize(token));
    }
    return splitTokens;
  }

  List<int> convertTokensToIds(List<String> tokens) {
    List<int> outputIds = [];
    for (var token in tokens) {
      outputIds.add(dic[token]!);
    }
    return outputIds;
  }
}

class WordpieceTokenizer {
  Map<String, int> dic;
  static const String UNKNOWN_TOKEN = "[UNK]"; // For unknown words.
  static const int MAX_INPUTCHARS_PER_WORD = 200;

  WordpieceTokenizer({required this.dic});

  List<String> tokenize(String text) {
    List<String> outputTokens = [];

    for (var token in BasicTokenizer.whitespaceTokenize(text)) {
      if (token.length > MAX_INPUTCHARS_PER_WORD) {
        outputTokens.add(UNKNOWN_TOKEN);
        continue;
      }

      bool isBad = false; // Mark if a word cannot be tokenized into known
      // subwords.
      int start = 0;
      List<String> subTokens = [];

      while (start < token.length) {
        String curSubStr = "";

        int end = token.length; // Longer substring matches first.
        while (start < end) {
          String subStr = (start == 0)
              ? token.substring(start, end)
              : "##${token.substring(start, end)}";
          if (dic.containsKey(subStr)) {
            curSubStr = subStr;
            break;
          }
          end--;
        }

        // The word doesn't contain any known subwords.
        if ("" == curSubStr) {
          isBad = true;
          break;
        }

        // curSubStr is the longeset subword that can be found.
        subTokens.add(curSubStr);

        // Proceed to tokenize the resident string.
        start = end;
      }

      if (isBad) {
        outputTokens.add(UNKNOWN_TOKEN);
      } else {
        outputTokens.addAll(subTokens);
      }
    }

    return outputTokens;
  }
}

// Runs basic whitespace cleaning and splitting on a piece of text.
class BasicTokenizer {
  bool doLowerCase;

  BasicTokenizer({required this.doLowerCase});

  List<String> tokenize(String text) {
    String cleanedText = cleanText(text);

    List<String> origTokens = whitespaceTokenize(cleanedText);
    StringBuffer sb = StringBuffer();
    for (var token in origTokens) {
      if (doLowerCase) {
        token = token.toLowerCase();
      }
      List<String> list = runSplitOnPunc(token);
      for (var subToken in list) {
        sb.write("$subToken ");
      }
    }
    return whitespaceTokenize(sb.toString());
  }

  // Performs invalid character removal and whitespace cleanup on text.
  static String cleanText(String text) {
    StringBuffer sb = StringBuffer("");
    for (int index = 0; index < text.length; index++) {
      String ch = text[index];
      if (CharChecker.isInvalid(ch) || CharChecker.isControlForBert(ch)) {
        continue;
      }
      if (CharChecker.isWhitespaceForBert(ch)) {
        sb.write(" ");
      } else {
        sb.write(ch);
      }
    }
    return sb.toString();
  }

  static List<String> whitespaceTokenize(String text) {
    return text.trim().split(" ");
  }

  // Splits punctuation on a piece of text.
  static List<String> runSplitOnPunc(String text) {
    List<String> tokens = [];
    bool startNewWord = true;
    for (int i = 0; i < text.length; i++) {
      String ch = text[i];
      if (CharChecker.isPunctuationForBert(ch)) {
        tokens.add(ch);
        startNewWord = true;
      } else {
        if (startNewWord) {
          tokens.add("");
          startNewWord = false;
        }
        tokens[tokens.length - 1] = tokens[tokens.length - 1] + ch;
      }
    }
    return tokens;
  }
}

// https://en.wikipedia.org/wiki/List_of_Unicode_characters#Special_areas_and_format_characters
class CharChecker {
  // To judge whether it can be regarded as a whitespace, "\n", "\t", "\r"
  static bool isWhitespaceForBert(String ch) {
    int type = ch.codeUnitAt(0);
    return type == 32 || type == 9 || type == 10 || type == 13;
  }

  // To judge whether it's an empty or unknown character.
  static bool isInvalid(String ch) {
    return (ch == String.fromCharCode(0) || ch == String.fromCharCode(0xFFFD));
  }

  // To judge whether it's a control character(exclude whitespace, "\n", "\t", "\r").
  static bool isControlForBert(String ch) {
    if (isWhitespaceForBert(ch)) {
      // whitespace
      return false;
    }

    int type = ch.codeUnitAt(0);
    return (type == 127 ||
        (type >= 1 && type <= 31) ||
        (type >= 128 && type <= 159));
  }

  // To judge whether it's a punctuation.
  static bool isPunctuationForBert(String ch) {
    int type = ch.codeUnitAt(0);
    return (type >= 33 && type <= 47) || // ASCII Punctuation & Symbols
            (type >= 58 && type <= 64) ||
            (type >= 91 && type <= 96) ||
            (type >= 123 && type <= 126) ||
            (type >= 160 && type <= 191) // Latin-1 Punctuation & Symbols
        ;
  }
}
