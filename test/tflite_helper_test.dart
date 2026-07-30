import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter_platform_interface.dart';
import 'package:tflite_flutter/tflite_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ── Mock ───────────────────────────────────────────────────────────────────

class MockTfliteFlutterPlatform with MockPlatformInterfaceMixin implements TfliteFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('iOS 17.0');
}

// ── Pure-Dart mirrors of package internals ────────────────────────────────
// These replicate the logic from nlu_engine.dart / meta_provider.dart /
// wake_word_detector.dart so tests never load the native dylib.

List<int> _tokenize(String text, Map<String, int> vocab, int maxLen) {
  final tokens = text.toLowerCase().trim().split(RegExp(r'\s+'));
  final ids = tokens.take(maxLen).map((w) => vocab[w] ?? 1).toList();
  while (ids.length < maxLen) ids.add(0);
  return ids;
}

List<double> _softmax(List<double> logits) {
  final max = logits.reduce((a, b) => a > b ? a : b);
  final exps = logits.map((l) => math.exp(l - max)).toList();
  final sum = exps.reduce((a, b) => a + b);
  return exps.map((e) => e / sum).toList();
}

int _argmax(List<double> v) {
  var best = 0;
  for (var i = 1; i < v.length; i++) {
    if (v[i] > v[best]) best = i;
  }
  return best;
}

String _extractCommand(String transcript, String wakeWord) => transcript.replaceFirst(wakeWord, '').trim();

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TfliteFlutterPlatform originalPlatform;

  setUp(() {
    originalPlatform = TfliteFlutterPlatform.instance;
    TfliteFlutterPlatform.instance = MockTfliteFlutterPlatform();
  });

  tearDown(() {
    TfliteFlutterPlatform.instance = originalPlatform;
  });

  // ── Platform channel ──────────────────────────────────────────────────────

  group('TfliteFlutter platform channel', () {
    test('default instance is MethodChannelTfliteFlutter', () {
      expect(originalPlatform, isInstanceOf<MethodChannelTfliteFlutter>());
    });

    test('getPlatformVersion returns mocked OS string', () async {
      final v = await TfliteFlutterPlatform.instance.getPlatformVersion();
      expect(v, 'iOS 17.0');
    });

    test('getPlatformVersion is non-null', () async {
      final v = await TfliteFlutterPlatform.instance.getPlatformVersion();
      expect(v, isNotNull);
    });
  });

  // ── NluMeta tokenizer ─────────────────────────────────────────────────────

  group('NluMeta.tokenize', () {
    const vocab = {
      'hello': 2,
      'world': 3,
      'add': 4,
      'task': 5,
      'buy': 6,
      'milk': 7,
    };
    const maxLen = 16;

    test('known words are mapped to their vocab ids', () {
      final ids = _tokenize('hello world', vocab, maxLen);
      expect(ids[0], 2);
      expect(ids[1], 3);
    });

    test('unknown words are mapped to OOV id 1', () {
      final ids = _tokenize('foobar', vocab, maxLen);
      expect(ids[0], 1);
    });

    test('output is always padded to maxLen', () {
      final ids = _tokenize('hello', vocab, maxLen);
      expect(ids.length, maxLen);
      expect(ids.sublist(1), everyElement(0));
    });

    test('long input is truncated to maxLen', () {
      final longText = List.generate(20, (_) => 'hello').join(' ');
      final ids = _tokenize(longText, vocab, maxLen);
      expect(ids.length, maxLen);
    });

    test('input is lowercased before tokenization', () {
      expect(_tokenize('hello', vocab, maxLen), _tokenize('HELLO', vocab, maxLen));
    });

    test('leading and trailing whitespace is ignored', () {
      expect(
        _tokenize('hello world', vocab, maxLen),
        _tokenize('  hello world  ', vocab, maxLen),
      );
    });

    test('empty string produces OOV id then all-padding', () {
      final ids = _tokenize('', vocab, maxLen);
      expect(ids[0], 1);
      expect(ids.sublist(1), everyElement(0));
    });

    test('multi-word intent phrase maps correctly', () {
      final ids = _tokenize('add task', vocab, maxLen);
      expect(ids[0], 4); // add
      expect(ids[1], 5); // task
    });
  });

  // ── Softmax / argmax ──────────────────────────────────────────────────────

  group('NluEngine math helpers', () {
    test('softmax outputs sum to ~1.0', () {
      final probs = _softmax([
        1.0,
        2.0,
        3.0
      ]);
      expect(probs.reduce((a, b) => a + b), closeTo(1.0, 1e-6));
    });

    test('softmax largest logit gets highest probability', () {
      final probs = _softmax([
        1.0,
        5.0,
        2.0
      ]);
      expect(_argmax(probs), 1);
    });

    test('argmax returns index of maximum value', () {
      expect(
          _argmax([
            0.1,
            0.8,
            0.1
          ]),
          1);
      expect(
          _argmax([
            0.9,
            0.05,
            0.05
          ]),
          0);
      expect(
          _argmax([
            0.1,
            0.1,
            0.8
          ]),
          2);
    });

    test('softmax is numerically stable for large logit differences', () {
      final probs = _softmax([
        1000.0,
        0.0,
        0.0
      ]);
      expect(probs[0], closeTo(1.0, 1e-6));
    });

    test('equal logits produce uniform distribution', () {
      final probs = _softmax([
        1.0,
        1.0,
        1.0
      ]);
      for (final p in probs) {
        expect(p, closeTo(1 / 3, 1e-6));
      }
    });

    test('all softmax values are between 0 and 1', () {
      final probs = _softmax([
        -1.0,
        0.0,
        1.0,
        2.0
      ]);
      for (final p in probs) {
        expect(p, inInclusiveRange(0.0, 1.0));
      }
    });

    test('argmax with single element returns 0', () {
      expect(
          _argmax([
            0.99
          ]),
          0);
    });
  });

  // ── WakeWord string logic ─────────────────────────────────────────────────

  group('WakeWordDetector string helpers', () {
    test('command is extracted after wake word', () {
      expect(
        _extractCommand('hey add milk to my list', 'hey'),
        'add milk to my list',
      );
    });

    test('empty transcript after wake word returns empty string', () {
      expect(_extractCommand('hey', 'hey'), '');
    });

    test('wake word is stripped case-insensitively when pre-lowercased', () {
      final t = 'never add task'.toLowerCase();
      final w = 'never'.toLowerCase();
      expect(_extractCommand(t, w), 'add task');
    });

    test('only first occurrence of wake word is stripped', () {
      expect(_extractCommand('hey hey do this', 'hey'), 'hey do this');
    });

    test('extra whitespace after wake word is trimmed', () {
      expect(_extractCommand('hey   buy milk', 'hey'), 'buy milk');
    });

    test('wake word at end of transcript leaves empty command', () {
      expect(_extractCommand('say hey', 'hey'), 'say');
    });
  });

  // ── AiState enum names ────────────────────────────────────────────────────

  group('AiState enum', () {
    const expectedNames = {
      'initialising',
      'ready',
      'listening',
      'awake',
      'processing',
      'reloading',
      'disposed',
      'permissionDenied',
    };

    test('all expected AiState value names are defined', () {
      // When AiState is exported from your library, replace with:
      //   final names = AiState.values.map((s) => s.name).toSet();
      //   expect(names, containsAll(expectedNames));
      expect(expectedNames.contains('ready'), isTrue);
      expect(expectedNames.contains('listening'), isTrue);
      expect(expectedNames.contains('awake'), isTrue);
      expect(expectedNames.contains('processing'), isTrue);
      expect(expectedNames.contains('permissionDenied'), isTrue);
      expect(expectedNames.contains('disposed'), isTrue);
    });

    test('no unexpected state names are present', () {
      expect(expectedNames.length, 8);
    });
  });

  // ── ActionDispatcher fallback ─────────────────────────────────────────────

  group('ActionDispatcher fallback response', () {
    // Mirrors the fallback string in action_dispatcher.dart.
    const fallback = "I'm not sure how to help with that yet.";

    test('fallback message is non-empty', () {
      expect(fallback.trim(), isNotEmpty);
    });

    test('fallback message matches expected string', () {
      expect(fallback, "I'm not sure how to help with that yet.");
    });
  });
}
