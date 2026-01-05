import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/providers/zhipu_provider.dart';

void main() {
  group('ZhipuProvider', () {
    late ZhipuProvider provider;

    setUp(() {
      provider = ZhipuProvider();
    });

    test('should have correct properties', () {
      expect(provider.name, equals('zhipu'));
      expect(provider.displayName, equals('Zhipu AI (Z.AI)'));
      expect(provider.isCloud, isTrue);
      expect(provider.requiresApiKey, isTrue);
    });

    test('should configure with baseUrl and apiKey', () {
      provider.configure(
        baseUrl: 'https://open.bigmodel.cn/api/paas',
        apiKey: 'test-key',
      );
      expect(() => provider.configure(
        baseUrl: 'https://open.bigmodel.cn/api/paas',
        apiKey: 'test-key',
      ), returnsNormally);
    });

    test('testConnection returns error with invalid key', () async {
      provider.configure(
        baseUrl: 'https://open.bigmodel.cn/api/paas',
        apiKey: 'invalid-key',
      );

      final error = await provider.testConnection();
      // Should return some error
      expect(error, isNotNull);
    });

    test('getAvailableModels returns hardcoded models', () async {
      provider.configure(
        baseUrl: 'https://open.bigmodel.cn/api/paas',
        apiKey: 'test-key',
      );

      final models = await provider.getAvailableModels();
      expect(models, isNotEmpty);
      expect(models.first, contains('glm'));
    });
  });
}
