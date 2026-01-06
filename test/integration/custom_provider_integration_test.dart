/**
 * Custom Provider Integration Tests with VCR
 *
 * Records and replays HTTP interactions with OpenAI-compatible API.
 * Uses dartvcr package for cassette-based testing.
 *
 * Usage:
 * - Record: VCR_MODE=record CUSTOM_API_KEY=xxx flutter test test/integration/custom_provider_integration_test.dart
 * - Replay: flutter test test/integration/custom_provider_integration_test.dart
 * - Live:   VCR_MODE=live CUSTOM_API_KEY=xxx flutter test test/integration/custom_provider_integration_test.dart
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/custom_provider.dart';
import 'package:flux_origin/services/ai_provider.dart';
import 'package:dartvcr/dartvcr.dart';
import 'package:http/http.dart' as http;

/// Test configuration
///
/// VCR mode is controlled by VCR_MODE environment variable.
/// Values: 'record', 'live', 'replay' (default)
bool get _isRecordMode {
  final mode = Platform.environment['VCR_MODE']?.toLowerCase();
  return mode == 'record';
}

bool get _isLiveMode {
  final mode = Platform.environment['VCR_MODE']?.toLowerCase();
  return mode == 'live';
}

/// Get API key from environment
///
/// Required for record and live modes. Returns a dummy key for replay mode.
String _getApiKey() {
  if (!_isRecordMode && !_isLiveMode) {
    return 'test-key-for-replay'; // Dummy key for replay
  }
  final key = Platform.environment['CUSTOM_API_KEY'];
  if (key == null || key.isEmpty) {
    throw Exception(
      'CUSTOM_API_KEY environment variable is required for recording. '
      'Export it with: export CUSTOM_API_KEY=...',
    );
  }
  return key;
}

/// Get base URL from environment or use default
String _getBaseUrl() {
  return Platform.environment['CUSTOM_BASE_URL'] ?? 'http://localhost:8317';
}

/// VCR test wrapper
///
/// Wraps test functions with VCR cassette management.
void main() {
  // Print usage information
  final mode = _isRecordMode ? 'RECORD' : _isLiveMode ? 'LIVE' : 'REPLAY';
  print('''
╔══════════════════════════════════════════════════════════════╗
║              Custom Provider Integration Tests                ║
╠══════════════════════════════════════════════════════════════╣
║  Mode: ${mode.padRight(50)}║
╚══════════════════════════════════════════════════════════════╝
''');

  group('CustomProvider Integration Tests', () {
    late CustomProvider provider;
    late VCR vcr;
    late http.Client vcrClient;
    // Cassettes directory for recorded HTTP interactions
    const String cassettesDir = 'test/integration/fixtures/cassettes';

    setUpAll(() {
      // Create VCR instance with censors for sensitive data
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
        cassette = Cassette(cassettesDir, 'custom_test_connection');
        vcr.insert(cassette);

        vcrClient = vcr.client;
        provider = CustomProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: _getBaseUrl(),
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('successfully connects with valid API key', () async {
        final result = await provider.testConnection();

        expect(result, isNull); // null means success
      });
    });

    group('chat', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'custom_chat');
        vcr.insert(cassette);

        vcrClient = vcr.client;
        provider = CustomProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: _getBaseUrl(),
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('returns response for simple prompt', () async {
        const prompt = 'Say "Hello, World!" in exactly those words.';
        const model = 'gpt-5.1';

        final response = await provider.chat(prompt, model);

        expect(response, isNotEmpty);
        expect(response.toLowerCase(), contains('hello'));
      });
    });

    group('chatStream', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'custom_chat_stream');
        vcr.insert(cassette);

        vcrClient = vcr.client;
        provider = CustomProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: _getBaseUrl(),
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test(
        'streams response chunks',
        () async {
          const prompt = 'Count from 1 to 3.';
          const model = 'gpt-5.1';

          final chunks = <String>[];
          await for (final chunk in provider.chatStream(prompt, model)) {
            chunks.add(chunk);
          }

          expect(chunks, isNotEmpty);
        },
        skip: !_isLiveMode
            ? 'Streaming tests require live mode (VCR does not support streaming)'
            : null,
        timeout: Timeout(Duration(minutes: 2)),
      );
    });
  });
}
