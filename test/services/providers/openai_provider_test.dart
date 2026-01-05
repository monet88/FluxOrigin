import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/openai_provider.dart';

void main() {
  group('OpenAIProvider', () {
    late OpenAIProvider provider;

    setUp(() {
      provider = OpenAIProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('openai'));
      expect(provider.displayName, equals('OpenAI'));
      expect(provider.isCloud, isTrue);
      expect(provider.requiresApiKey, isTrue);
    });

    test('should configure with baseUrl and apiKey', () {
      provider.configure(
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
      );
      expect(() => provider.configure(
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
      ), returnsNormally);
    });

    test('testConnection returns error with invalid key', () async {
      provider.configure(
        baseUrl: 'https://api.openai.com',
        apiKey: 'invalid-key',
      );

      final error = await provider.testConnection();
      // Should return some error (auth, connection, or unknown depending on network)
      expect(error, isNotNull);
    });

    test('getAvailableModels returns hardcoded models', () async {
      provider.configure(
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-test-key',
      );

      final models = await provider.getAvailableModels();
      expect(models, isNotEmpty);
      expect(models.first, contains('gpt'));
    });
  });
}
