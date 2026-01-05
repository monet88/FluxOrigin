import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/lm_studio_provider.dart';
import 'package:flux_origin/services/ai_provider.dart';

void main() {
  group('LMStudioProvider', () {
    late LMStudioProvider provider;

    setUp(() {
      provider = LMStudioProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('lmStudio'));
      expect(provider.displayName, equals('LM Studio (Local)'));
      expect(provider.isCloud, isFalse);
      expect(provider.requiresApiKey, isFalse);
    });

    test('should configure with baseUrl', () {
      provider.configure(baseUrl: 'http://localhost:1234');
      expect(() => provider.configure(baseUrl: 'http://localhost:1234'), returnsNormally);
    });

    test('testConnection returns timeout when unreachable', () async {
      provider.configure(baseUrl: 'http://invalid-host:1234');

      final error = await provider.testConnection();
      expect(error, equals(AIProviderError.timeout));
    });

    test('getAvailableModels returns empty list on error', () async {
      provider.configure(baseUrl: 'http://invalid-host:1234');

      final models = await provider.getAvailableModels();
      expect(models, isEmpty);
    });
  });
}
