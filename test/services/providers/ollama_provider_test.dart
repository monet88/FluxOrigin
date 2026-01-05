import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/ollama_provider.dart';
import 'package:flux_origin/services/ai_provider.dart';

void main() {
  group('OllamaProvider', () {
    late OllamaProvider provider;

    setUp(() {
      provider = OllamaProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('ollama'));
      expect(provider.displayName, equals('Ollama (Local)'));
      expect(provider.isCloud, isFalse);
      expect(provider.requiresApiKey, isFalse);
    });

    test('should configure with baseUrl', () {
      provider.configure(baseUrl: 'http://localhost:11434');
      // Configuration should succeed without throwing
      expect(() => provider.configure(baseUrl: 'http://localhost:11434'), returnsNormally);
    });

    test('getAvailableModels returns empty list on error', () async {
      provider.configure(baseUrl: 'http://invalid-host:11434');

      // Returns empty list instead of throwing
      final models = await provider.getAvailableModels();
      expect(models, isEmpty);
    });

    test('testConnection returns timeout when unreachable', () async {
      provider.configure(baseUrl: 'http://invalid-host:11434');

      final error = await provider.testConnection();
      expect(error, equals(AIProviderError.timeout));
    });

    test('chat throws AIProviderError when server unreachable', () async {
      provider.configure(baseUrl: 'http://invalid-host:11434');

      expect(
        () => provider.chat('Hello', 'qwen2.5:7b'),
        throwsA(isA<AIProviderError>()),
      );
    });
  });
}
