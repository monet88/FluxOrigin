import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/gemini_provider.dart';

void main() {
  group('GeminiProvider', () {
    late GeminiProvider provider;

    setUp(() {
      provider = GeminiProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('gemini'));
      expect(provider.displayName, equals('Google Gemini'));
      expect(provider.isCloud, isTrue);
      expect(provider.requiresApiKey, isTrue);
    });

    test('should configure with baseUrl and apiKey', () {
      provider.configure(
        baseUrl: 'https://generativelanguage.googleapis.com',
        apiKey: 'test-key',
      );
      expect(() => provider.configure(
        baseUrl: 'https://generativelanguage.googleapis.com',
        apiKey: 'test-key',
      ), returnsNormally);
    });

    test('testConnection returns error with invalid key', () async {
      provider.configure(
        baseUrl: 'https://generativelanguage.googleapis.com',
        apiKey: 'invalid-key',
      );

      final error = await provider.testConnection();
      // Should return some error (auth, connection, or unknown)
      expect(error, isNotNull);
    });

    test('getAvailableModels returns hardcoded models', () async {
      provider.configure(
        baseUrl: 'https://generativelanguage.googleapis.com',
        apiKey: 'test-key',
      );

      final models = await provider.getAvailableModels();
      expect(models, isNotEmpty);
      expect(models.first, contains('gemini'));
    });
  });
}
