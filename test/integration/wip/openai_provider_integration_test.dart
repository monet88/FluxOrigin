/**
 * OpenAI Provider Integration Tests with VCR
 *
 * Records and replays HTTP interactions with OpenAI API.
 * Uses dartvcr package for cassette-based testing.
 *
 * Usage:
 * - Record: flutter test test/integration/providers/openai_provider_integration_test.dart --record
 * - Replay: flutter test test/integration/providers/openai_provider_integration_test.dart --mock
 * - Live:   flutter test test/integration/providers/openai_provider_integration_test.dart --live
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/openai_provider.dart';
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
    return 'sk-test-key-for-replay'; // Dummy key for replay
  }
  final key = Platform.environment['OPENAI_API_KEY'];
  if (key == null || key.isEmpty) {
    throw Exception(
      'OPENAI_API_KEY environment variable is required for recording. '
      'Export it with: export OPENAI_API_KEY=sk-...',
    );
  }
  return key;
}

/// VCR test wrapper
///
/// Wraps test functions with VCR cassette management.
void main() {
  // Print usage information
  print('''
╔══════════════════════════════════════════════════════════════╗
║              OpenAI Provider Integration Tests                ║
╠══════════════════════════════════════════════════════════════╣
║  Mode: ${_vcrMode.name.padRight(50)}║
╚══════════════════════════════════════════════════════════════╝
''');

  group('OpenAIProvider Integration Tests', () {
    late OpenAIProvider provider;
    late VCR vcr;
    late http.Client vcrClient;
    static const String cassettesDir = 'test/integration/fixtures/cassettes';

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

    group('testConnection', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'openai_test_connection');
        vcr.insert(cassette);

        // Set VCR mode
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

        // Create VCR client and inject it into provider
        vcrClient = vcr.client;
        provider = OpenAIProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.openai.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('successfully connects with valid API key', () async {
        final error = await provider.testConnection();

        expect(error, isNull, reason: 'Should connect successfully');
      });

      test('returns authenticationFailed with invalid API key', () async {
        // Only run this test in record or live mode
        // In replay mode, we use a dummy key which will fail auth
        if (_vcrMode == VCRMode.replay) {
          // Skip this test in replay mode as we're using a dummy key
          return;
        }

        provider.configure(
          baseUrl: 'https://api.openai.com',
          apiKey: 'sk-invalid-key',
        );

        final error = await provider.testConnection();

        expect(
          error,
          equals(AIProviderError.authenticationFailed),
          reason: 'Should return authenticationFailed error',
        );
      });
    });

    group('getAvailableModels', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'openai_get_models');
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
        provider = OpenAIProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.openai.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('returns list of available models', () async {
        final models = await provider.getAvailableModels();

        expect(models, isNotEmpty, reason: 'Should return at least one model');
        expect(
          models.any((m) => m.contains('gpt')),
          isTrue,
          reason: 'Should include GPT models',
        );
      });
    });

    group('chat', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'openai_chat');
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
        provider = OpenAIProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.openai.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('returns response for simple prompt', () async {
        const prompt = 'Say "Hello, World!" in exactly those words.';
        const model = 'gpt-4o-mini';

        final response = await provider.chat(prompt, model);

        expect(
          response,
          isNotEmpty,
          reason: 'Should return a non-empty response',
        );
        expect(
          response.toLowerCase(),
          contains('hello'),
          reason: 'Response should contain greeting',
        );
      });

      test('handles temperature option', () async {
        const prompt = 'Generate a random word.';
        const model = 'gpt-4o-mini';
        final options = {'temperature': 0.7, 'max_tokens': 10};

        final response = await provider.chat(prompt, model, options: options);

        expect(response, isNotEmpty);
      });
    });

    group('chatStream', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'openai_chat_stream');
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
        provider = OpenAIProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.openai.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('streams response chunks', () async {
        const prompt = 'Count from 1 to 5 slowly.';
        const model = 'gpt-4o-mini';

        final chunks = <String>[];
        await for (final chunk in provider.chatStream(prompt, model)) {
          chunks.add(chunk);
        }

        expect(chunks, isNotEmpty, reason: 'Should receive at least one chunk');
        final fullResponse = chunks.join();
        expect(fullResponse, isNotEmpty);
      });

      test('completes stream when done', () async {
        const prompt = 'Say "Done" when finished.';
        const model = 'gpt-4o-mini';

        var chunkCount = 0;
        await for (final chunk in provider.chatStream(prompt, model)) {
          chunkCount++;
          // Limit chunks to avoid infinite streaming in test
          if (chunkCount > 100) break;
        }

        expect(chunkCount, greaterThan(0));
      });
    });

    group('error handling', () {
      late Cassette cassette;

      setUp(() {
        cassette = Cassette(cassettesDir, 'openai_errors');
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
        provider = OpenAIProvider();
        provider.setHttpClient(vcrClient);
        provider.configure(
          baseUrl: 'https://api.openai.com',
          apiKey: _getApiKey(),
        );
      });

      tearDown(() {
        vcr.eject();
      });

      test('throws error for invalid model', () async {
        if (_vcrMode == VCRMode.replay) {
          // Skip in replay mode - requires real API for new error recording
          return;
        }

        const prompt = 'Test';
        const model = 'gpt-invalid-model';

        expect(
          () => provider.chat(prompt, model),
          throwsA(isA<AIProviderError>()),
        );
      });
    });
  });
}

/// VCR Mode enum (mirrors dartvcr's Mode)
enum VCRMode { record, replay, auto, bypass }
