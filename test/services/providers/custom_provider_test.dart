import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/custom_provider.dart';
import 'package:flux_origin/services/ai_provider.dart';

void main() {
  group('CustomProvider', () {
    late CustomProvider provider;

    setUp(() {
      provider = CustomProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('custom'));
      expect(provider.displayName, equals('Custom (OpenAI-Compatible)'));
      expect(provider.isCloud, isFalse);
      expect(provider.requiresApiKey, isFalse);
    });

    test('should configure with baseUrl and optional apiKey', () {
      provider.configure(baseUrl: 'http://localhost:8080');
      expect(() => provider.configure(baseUrl: 'http://localhost:8080'), returnsNormally);

      provider.configure(baseUrl: 'http://localhost:8080', apiKey: 'optional-key');
      expect(() => provider.configure(
        baseUrl: 'http://localhost:8080',
        apiKey: 'optional-key',
      ), returnsNormally);
    });

    test('testConnection returns timeout when server unreachable', () async {
      provider.configure(baseUrl: 'http://invalid-host:8080');

      final error = await provider.testConnection();
      expect(error, equals(AIProviderError.timeout));
    });

    test('getAvailableModels returns empty list on error', () async {
      provider.configure(baseUrl: 'http://invalid-host:8080');

      final models = await provider.getAvailableModels();
      expect(models, isEmpty);
    });

    test('getAvailableModels returns empty list when baseUrl empty', () async {
      provider.configure(baseUrl: '');

      final models = await provider.getAvailableModels();
      expect(models, isEmpty);
    });
  });
}
