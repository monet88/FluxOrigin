import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';
import '../model_registry.dart';

/// DeepSeek Cloud AI Provider
///
/// Implements AIProvider for DeepSeek's cloud API service.
/// DeepSeek uses OpenAI-compatible API format with Bearer token authentication.
/// Base URL: https://api.deepseek.com
class DeepSeekProvider implements AIProvider {
  @override
  String get name => 'deepseek';

  @override
  String get displayName => 'DeepSeek';

  @override
  bool get isCloud => true;

  @override
  bool get requiresApiKey => true;

  /// Configured base URL (default: https://api.deepseek.com)
  String _baseUrl = 'https://api.deepseek.com';

  /// API key for Bearer token authentication (required)
  String? _apiKey;

  /// Timeout constants (as per requirements)
  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _defaultChatTimeout = Duration(seconds: 60);
  static const Duration _defaultChatStreamTimeout = Duration(seconds: 120);

  @override
  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  @override
  Future<AIProviderError?> testConnection() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return AIProviderError.authenticationFailed;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/models'),
            headers: _buildHeaders(),
          )
          .timeout(_testTimeout);

      // Map HTTP status codes to AIProviderError
      if (response.statusCode == 200) {
        return null; // Success
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return AIProviderError.authenticationFailed;
      } else if (response.statusCode == 429) {
        return AIProviderError.rateLimited;
      } else if (response.statusCode >= 500) {
        return AIProviderError.connectionFailed;
      } else {
        return AIProviderError.unknown;
      }
    } on TimeoutException {
      return AIProviderError.timeout;
    } on SocketException catch (_) {
      return AIProviderError.connectionFailed;
    } catch (_) {
      return AIProviderError.unknown;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    // Cloud provider: return hardcoded models from ModelRegistry
    // No need to fetch from API since models are pre-defined
    try {
      final models = ModelRegistry.models['deepseek'];
      if (models != null) {
        return models.map((m) => m.id).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
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
      final requestBody = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'stream': false,
        ...?options,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/v1/chat/completions'),
            headers: _buildHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(timeout ?? _defaultChatTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          return message?['content'] as String? ?? '';
        }
        return '';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AIProviderError.authenticationFailed;
      } else if (response.statusCode == 404) {
        throw AIProviderError.modelNotFound;
      } else if (response.statusCode == 429) {
        throw AIProviderError.rateLimited;
      } else if (response.statusCode >= 500) {
        throw AIProviderError.connectionFailed;
      } else {
        throw AIProviderError.unknown;
      }
    } on TimeoutException {
      throw AIProviderError.timeout;
    } on SocketException {
      throw AIProviderError.connectionFailed;
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
      final requestBody = {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'stream': true,
        ...?options,
      };

      final request = http.StreamedRequest(
        'POST',
        Uri.parse('$_baseUrl/v1/chat/completions'),
      );
      request.headers.addAll(_buildHeaders());
      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      final responseFuture = http.Client().send(request);
      final streamedResponse = await responseFuture
          .timeout(timeout ?? _defaultChatStreamTimeout);

      if (streamedResponse.statusCode == 401 ||
          streamedResponse.statusCode == 403) {
        throw AIProviderError.authenticationFailed;
      } else if (streamedResponse.statusCode == 404) {
        throw AIProviderError.modelNotFound;
      } else if (streamedResponse.statusCode == 429) {
        throw AIProviderError.rateLimited;
      } else if (streamedResponse.statusCode >= 500) {
        throw AIProviderError.connectionFailed;
      } else if (streamedResponse.statusCode != 200) {
        throw AIProviderError.unknown;
      }

      // Parse SSE (OpenAI-compatible format)
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
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
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
    } on AIProviderError {
      rethrow;
    } catch (_) {
      throw AIProviderError.unknown;
    }
  }

  /// Build HTTP headers with Bearer token authentication
  ///
  /// DeepSeek uses standard OpenAI-compatible auth format:
  /// Authorization: Bearer {api_key}
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }

    return headers;
  }
}
