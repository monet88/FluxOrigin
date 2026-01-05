import 'dart:async';
import 'package:flux_origin/services/ai_provider.dart';

/**
 * Mock AI Provider for Testing
 *
 * Implements AIProvider interface for unit testing.
 * Supports simulation of all error types and response patterns.
 */
class MockAIProvider extends AIProvider {
  // Configuration state
  // ignore: unused_field
  String _baseUrl = '';
  // ignore: unused_field
  String? _apiKey;
  bool _isConfigured = false;

  // Mock response configuration
  String? _mockChatResponse;
  List<String> _mockStreamChunks = [];
  List<String> _mockModels = ['mock-model-1', 'mock-model-2'];
  AIProviderError? _mockError;
  int _callCount = 0;

  // Getters
  @override
  String get name => 'mock';

  @override
  String get displayName => 'Mock Provider';

  @override
  bool get isCloud => false;

  @override
  bool get requiresApiKey => false;

  // Configuration
  @override
  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _isConfigured = true;
  }

  // Test configuration methods
  /// Set the mock response for chat() calls
  void setMockChatResponse(String response) {
    _mockChatResponse = response;
  }

  /// Set the mock chunks for chatStream() calls
  void setMockStreamChunks(List<String> chunks) {
    _mockStreamChunks = chunks;
  }

  /// Set the mock model list
  void setMockModels(List<String> models) {
    _mockModels = models;
  }

  /// Set the mock error to return from testConnection()
  void setMockError(AIProviderError? error) {
    _mockError = error;
  }

  /// Reset all mock state
  void reset() {
    _baseUrl = '';
    _apiKey = null;
    _isConfigured = false;
    _mockChatResponse = null;
    _mockStreamChunks = [];
    _mockModels = ['mock-model-1', 'mock-model-2'];
    _mockError = null;
    _callCount = 0;
  }

  /// Get the number of times testConnection() was called
  int get callCount => _callCount;

  // AIProvider interface implementation
  @override
  Future<AIProviderError?> testConnection() async {
    _callCount++;
    if (!_isConfigured) {
      return AIProviderError.connectionFailed;
    }
    return _mockError;
  }

  @override
  Future<List<String>> getAvailableModels() async {
    if (_mockError != null) {
      throw Exception('Mock error: $_mockError');
    }
    return _mockModels;
  }

  @override
  Future<String> chat(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  }) async {
    if (_mockError != null) {
      throw _mapErrorToException(_mockError!);
    }
    if (_mockChatResponse != null) {
      return _mockChatResponse!;
    }
    return 'Mock response to: $prompt';
  }

  @override
  Stream<String> chatStream(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  }) async* {
    if (_mockError != null) {
      throw _mapErrorToException(_mockError!);
    }
    if (_mockStreamChunks.isNotEmpty) {
      for (final chunk in _mockStreamChunks) {
        await Future.delayed(const Duration(milliseconds: 10));
        yield chunk;
      }
    } else {
      yield 'Mock ';
      await Future.delayed(const Duration(milliseconds: 10));
      yield 'stream ';
      await Future.delayed(const Duration(milliseconds: 10));
      yield 'response';
    }
  }

  Exception _mapErrorToException(AIProviderError error) {
    switch (error) {
      case AIProviderError.connectionFailed:
        return Exception('Connection failed');
      case AIProviderError.authenticationFailed:
        return Exception('Authentication failed');
      case AIProviderError.rateLimited:
        return Exception('Rate limited');
      case AIProviderError.modelNotFound:
        return Exception('Model not found');
      case AIProviderError.timeout:
        return TimeoutException('Request timeout', const Duration(seconds: 30));
      case AIProviderError.unknown:
        return Exception('Unknown error');
    }
  }
}
