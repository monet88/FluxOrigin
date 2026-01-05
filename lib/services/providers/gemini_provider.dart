import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';
import '../model_registry.dart';

/// Google Gemini AI Provider
///
/// Implements AIProvider for Google Gemini API.
/// Gemini uses a unique request/response format with `contents` array
/// and API key passed as query parameter (not header).
///
/// API Documentation: https://ai.google.dev/docs
class GeminiProvider implements AIProvider {
  /// Internal identifier
  @override
  String get name => 'gemini';

  /// Display name for UI
  @override
  String get displayName => 'Google Gemini';

  /// Cloud provider, requires internet
  @override
  bool get isCloud => true;

  /// API key required for authentication
  @override
  bool get requiresApiKey => true;

  /// Configured base URL (default: https://generativelanguage.googleapis.com)
  String _baseUrl = 'https://generativelanguage.googleapis.com';

  /// API key for authentication (passed as query parameter)
  String? _apiKey;

  /// Optional HTTP client for testing (e.g., VCR recording/replay)
  http.Client? _testClient;

  /// Timeout constants
  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _defaultChatTimeout = Duration(seconds: 60);
  static const Duration _defaultStreamTimeout = Duration(seconds: 120);

  // Cloud providers use hardcoded models from ModelRegistry, so this is unused
  // ignore: unused_field
  static const Duration _modelsTimeout = Duration(seconds: 10);

  @override
  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  /// Set a custom HTTP client for testing
  ///
  /// Allows injecting a VCR client for recording/replay without modifying
  /// the core provider logic.
  void setHttpClient(http.Client client) {
    _testClient = client;
  }

  /// Get the HTTP client to use for requests
  ///
  /// Returns the test client if set, otherwise creates a default client.
  http.Client get _client => _testClient ?? http.Client();

  /// Build URL with API key as query parameter
  ///
  /// Gemini requires API key in URL: /v1beta/models/{model}:generateContent?key=xxx
  Uri _buildUrl(String model) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw ArgumentError('API key is required for Gemini provider');
    }
    return Uri.parse('$_baseUrl/v1beta/models/$model:generateContent?key=$_apiKey');
  }

  /// Map HTTP status code to AIProviderError
  AIProviderError _mapError(int statusCode) {
    switch (statusCode) {
      case 401:
      case 403:
        return AIProviderError.authenticationFailed;
      case 429:
        return AIProviderError.rateLimited;
      case 404:
        return AIProviderError.modelNotFound;
      default:
        return statusCode >= 500
            ? AIProviderError.connectionFailed
            : AIProviderError.unknown;
    }
  }

  @override
  Future<AIProviderError?> testConnection() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return AIProviderError.authenticationFailed;
    }

    try {
      // Use a simple request with the smallest model to test connection
      final url = _buildUrl('gemini-3-flash');

      final requestBody = {
        'contents': [
          {
            'parts': [{'text': 'test'}]
          }
        ],
      };

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_testTimeout);

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return _mapError(response.statusCode);
      }
    } on TimeoutException {
      return AIProviderError.timeout;
    } on SocketException catch (_) {
      return AIProviderError.connectionFailed;
    } on ArgumentError catch (_) {
      return AIProviderError.authenticationFailed;
    } catch (_) {
      return AIProviderError.unknown;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    // Cloud providers use hardcoded models from ModelRegistry
    final modelInfos = ModelRegistry.models['gemini'] ?? [];
    return modelInfos.map((m) => m.id).toList();
  }

  @override
  Future<String> chat(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw AIProviderError.authenticationFailed;
    }

    try {
      // Build Gemini request format
      final requestBody = {
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ],
        // Add generation config if options provided
        if (options != null) 'generationConfig': _buildGenerationConfig(options),
      };

      final response = await _client
          .post(
            _buildUrl(model),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout ?? _defaultChatTimeout);

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        throw _mapError(response.statusCode);
      }
    } on TimeoutException {
      throw AIProviderError.timeout;
    } on SocketException {
      throw AIProviderError.connectionFailed;
    } on ArgumentError {
      throw AIProviderError.authenticationFailed;
    } on AIProviderError {
      rethrow;
    } catch (_) {
      throw AIProviderError.unknown;
    }
  }

  @override
  Stream<String> chatStream(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  }) async* {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw AIProviderError.authenticationFailed;
    }

    try {
      // Build streaming request
      final requestBody = {
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ],
        if (options != null) 'generationConfig': _buildGenerationConfig(options),
      };

      final request = http.StreamedRequest('POST', _buildUrl(model));
      request.headers['Content-Type'] = 'application/json';
      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      final responseFuture = _client.send(request);
      final streamedResponse = timeout == null
          ? await responseFuture.timeout(_defaultStreamTimeout)
          : await responseFuture.timeout(timeout);

      if (streamedResponse.statusCode != 200) {
        throw _mapError(streamedResponse.statusCode);
      }

      // Parse SSE stream
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isEmpty) continue;
        if (!line.startsWith('data: ')) continue;

        final data = line.substring(6); // Remove 'data: ' prefix
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;

          // Check for errors
          if (json.containsKey('error')) {
            throw AIProviderError.unknown;
          }

          // Extract content from candidates
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          }
        } catch (_) {
          // Skip invalid JSON lines
        }
      }
    } on TimeoutException {
      throw AIProviderError.timeout;
    } on SocketException {
      throw AIProviderError.connectionFailed;
    } on ArgumentError {
      throw AIProviderError.authenticationFailed;
    } on AIProviderError {
      rethrow;
    } catch (_) {
      throw AIProviderError.unknown;
    }
  }

  /// Parse Gemini response format
  ///
  /// Extract text from: candidates[0].content.parts[0].text
  String _parseResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      // Check for API error
      if (json.containsKey('error')) {
        final error = json['error'] as Map<String, dynamic>;
        final code = error['code'] as int?;
        if (code != null) {
          throw _mapError(code);
        }
        throw AIProviderError.unknown;
      }

      // Extract content from candidates array
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return '';
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return '';
      }

      return parts[0]['text'] as String? ?? '';
    } catch (_) {
      throw AIProviderError.unknown;
    }
  }

  /// Build generationConfig from options
  ///
  /// Maps common options (temperature, maxTokens, etc.) to Gemini format
  Map<String, dynamic> _buildGenerationConfig(Map<String, dynamic> options) {
    final config = <String, dynamic>{};

    // Temperature: 0.0 - 2.0 (Gemin default: 0.7)
    if (options.containsKey('temperature')) {
      config['temperature'] = options['temperature'] as num;
    }

    // Max output tokens
    if (options.containsKey('maxTokens')) {
      config['maxOutputTokens'] = options['maxTokens'] as int;
    }

    // Top-K: 1-40 (default: 40)
    if (options.containsKey('topK')) {
      config['topK'] = options['topK'] as int;
    }

    // Top-P: 0.0-1.0 (default: 0.95)
    if (options.containsKey('topP')) {
      config['topP'] = options['topP'] as num;
    }

    // Stop sequences
    if (options.containsKey('stopSequences')) {
      final sequences = options['stopSequences'] as List<dynamic>?;
      if (sequences != null) {
        config['stopSequences'] = sequences.cast<String>();
      }
    }

    return config;
  }
}
