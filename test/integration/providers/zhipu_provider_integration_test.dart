/**
 * Zhipu Provider Integration Tests with VCR
 *
 * Records and replays HTTP interactions with Zhipu AI API.
 * Uses dartvcr package for cassette-based testing.
 *
 * Usage:
 * - Record: flutter test test/integration/providers/zhipu_provider_integration_test.dart --record
 * - Replay: flutter test test/integration/providers/zhipu_provider_integration_test.dart --mock
 * - Live:   flutter test test/integration/providers/zhipu_provider_integration_test.dart --live
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/zhipu_provider.dart';
import 'package:flux_origin/services/ai_provider.dart';
import 'package:dartvcr/dartvcr.dart';
import 'package:http/http.dart' as http;

/// Test configuration
///
/// VCR mode is controlled by command-line arguments.
VCRMode get _vcrMode {
  final args = Platform.executableArguments;
  if (args.contains('--record')) return VCRMode.record;
  if (args.contains('--live')) return VCRMode.bypass;
  return VCRMode.replay; // Default
}

/// Get API key from environment
///
/// Required for record and live modes. Returns a dummy key for replay mode.
String _getApiKey() {
  if (_vcrMode == VCRMode.replay) {
    return 'test-key-for-replay';
  }
  final key = Platform.environment['ZHIPU_API_KEY'];
  if (key == null || key.isEmpty) {
    throw Exception(
      'ZHIPU_API_KEY environment variable is required for recording. '
      'Export it with: export ZHIPU_API_KEY=...',
    );
  }
  return key;
}

void main() {
  print('''
╔══════════════════════════════════════════════════════════════╗
║               Zhipu Provider Integration Tests                ║
╠══════════════════════════════════════════════════════════════╣
║  Mode: ${_vcrMode.name.padRight(50)}║
╚══════════════════════════════════════════════════════════════╝
''');

  group('ZhipuProvider Integration Tests', () {
    late ZhipuProvider provider;
    late VCR vcr;
    late http.Client vcrClient;
    static const String cassettesDir = 'test/integration/fixtures/cassettes';

    setUpAll(() {
      final censors = Censors()
          .censorHeaderElementsByKeys(['authorization', 'x-api-key'])
          .censorQueryElementsByKeys(['key', 'api_key']);

      final advancedOptions = AdvancedOptions(
        censors: censors,
        simulateDelay: false,
      );

      vcr = VCR(advancedOptions: advancedOptions);
    });

    group('testConnection', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'zhipu_test_connection');
        vcr.insert(cassette);

        switch (_vcrMode) {
          case VCRMode.record:
            vcr.record();
            break;
          case VCRMode.replay:
            vcr.replay();
            break;
          case VCRMode.auto:
            vcr.auto();
            break;
          case VCRMode.bypass:
            vcr.bypass();
            break;
        }

        vcrClient = vcr.client;
        provider = ZhipuProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://open.bigmodel.cn',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('successfully connects with valid API key', () async {
        final error = await provider.testConnection();
        expect(error, isNull);
      });
    });

    group('chat', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'zhipu_chat');
        vcr.insert(cassette);

        switch (_vcrMode) {
          case VCRMode.record:
            vcr.record();
            break;
          case VCRMode.replay:
            vcr.replay();
            break;
          case VCRMode.auto:
            vcr.auto();
            break;
          case VCRMode.bypass:
            vcr.bypass();
            break;
        }

        vcrClient = vcr.client;
        provider = ZhipuProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://open.bigmodel.cn',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('returns response for simple prompt', () async {
        const prompt = 'Say "Hello, World!" in exactly those words.';
        const model = 'glm-4-flash';

        final response = await provider.chat(prompt, model);

        expect(response, isNotEmpty);
        expect(response.toLowerCase(), contains('hello'));
      });
    });

    group('chatStream', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'zhipu_chat_stream');
        vcr.insert(cassette);

        switch (_vcrMode) {
          case VCRMode.record:
            vcr.record();
            break;
          case VCRMode.replay:
            vcr.replay();
            break;
          case VCRMode.auto:
            vcr.auto();
            break;
          case VCRMode.bypass:
            vcr.bypass();
            break;
        }

        vcrClient = vcr.client;
        provider = ZhipuProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://open.bigmodel.cn',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('streams response chunks', () async {
        const prompt = 'Count from 1 to 3.';
        const model = 'glm-4-flash';

        final chunks = <String>[];
        await for (final chunk in provider.chatStream(prompt, model)) {
          chunks.add(chunk);
        }

        expect(chunks, isNotEmpty);
      });
    });
  });
}

enum VCRMode { record, replay, auto, bypass }
