import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/deepseek_provider.dart';

void main() {
  group('DeepSeekProvider', () {
    late DeepSeekProvider provider;

    setUp(() {
      provider = DeepSeekProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('deepseek'));
      expect(provider.displayName, equals('DeepSeek'));
      expect(provider.isCloud, isTrue);
      expect(provider.requiresApiKey, isTrue);
    });

    test('should configure with baseUrl and apiKey', () {
      provider.configure(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'sk-test-key',
      );
      expect(() => provider.configure(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'sk-test-key',
      ), returnsNormally);
    });

    test('testConnection returns error with invalid key', () async {
      provider.configure(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'invalid-key',
      );

      final error = await provider.testConnection();
      // Should return some error
      expect(error, isNotNull);
    });

    test('getAvailableModels returns hardcoded models', () async {
      provider.configure(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'test-key',
      );

      final models = await provider.getAvailableModels();
      expect(models, isNotEmpty);
      expect(models.first, contains('deepseek'));
    });
  });
}
