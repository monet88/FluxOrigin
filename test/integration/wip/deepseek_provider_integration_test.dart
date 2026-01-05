/**
 * DeepSeek Provider Integration Tests with VCR
 *
 * Records and replays HTTP interactions with DeepSeek API.
 * Uses dartvcr package for cassette-based testing.
 *
 * Usage:
 * - Record: flutter test test/integration/providers/deepseek_provider_integration_test.dart --record
 * - Replay: flutter test test/integration/providers/deepseek_provider_integration_test.dart --mock
 * - Live:   flutter test test/integration/providers/deepseek_provider_integration_test.dart --live
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/deepseek_provider.dart';
import 'package:flux_origin/services/ai_provider.dart';
import 'package:dartvcr/dartvcr.dart';
import 'package:http/http.dart' as http;

/// Test configuration
///
/// VCR mode is controlled by command-line arguments.
bool get _isRecordMode {
  final args = Platform.executableArguments;
  return args.contains('--record');
}

bool get _isLiveMode {
  final args = Platform.executableArguments;
  return args.contains('--live');
}

/// Get API key from environment
///
/// Required for record and live modes. Returns a dummy key for replay mode.
String _getApiKey() {
  if (!_isRecordMode && !_isLiveMode) {
    return 'sk-test-key-for-replay';
  }
  final key = Platform.environment['DEEPSEEK_API_KEY'];
  if (key == null || key.isEmpty) {
    throw Exception(
      'DEEPSEEK_API_KEY environment variable is required for recording. '
      'Export it with: export DEEPSEEK_API_KEY=sk-...',
    );
  }
  return key;
}

void main() {
  final mode = _isRecordMode ? 'RECORD' : _isLiveMode ? 'LIVE' : 'REPLAY';
  print('''
╔══════════════════════════════════════════════════════════════╗
║              DeepSeek Provider Integration Tests              ║
╠══════════════════════════════════════════════════════════════╣
║  Mode: ${mode.padRight(50)}║
╚══════════════════════════════════════════════════════════════╝
''');

  group('DeepSeekProvider Integration Tests', () {
    late DeepSeekProvider provider;
    late VCR vcr;
    late http.Client vcrClient;
    const String cassettesDir = 'test/integration/fixtures/cassettes';

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

    setUp(() {
      // Set VCR mode before each test
      if (_isRecordMode) {
        vcr.record();
      } else if (_isLiveMode) {
        vcr.record(); // Live mode still records, but makes real calls
      } else {
        vcr.replay();
      }
    });

    group('testConnection', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'deepseek_test_connection');
        vcr.insert(cassette);

        vcrClient = vcr.client;
        provider = DeepSeekProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.deepseek.com',
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
        cassette = Cassette(cassettesDir, 'deepseek_chat');
        vcr.insert(cassette);

        vcrClient = vcr.client;
        provider = DeepSeekProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.deepseek.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('returns response for simple prompt', () async {
        const prompt = 'Say "Hello, World!" in exactly those words.';
        const model = 'deepseek-chat';

        final response = await provider.chat(prompt, model);

        expect(response, isNotEmpty);
        expect(response.toLowerCase(), contains('hello'));
      });
    });

    group('chatStream', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'deepseek_chat_stream');
        vcr.insert(cassette);

        vcrClient = vcr.client;
        provider = DeepSeekProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.deepseek.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('streams response chunks', () async {
        const prompt = 'Count from 1 to 3.';
        const model = 'deepseek-chat';

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
