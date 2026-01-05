import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';
import '../model_registry.dart';

/// Zhipu AI (Z.AI / BigModel) Provider
///
/// Implements AIProvider for Zhipu AI cloud service.
/// Zhipu uses OpenAI-compatible API format with v4 endpoints.
/// Base URL: https://open.bigmodel.cn/api/paas
///
/// Authentication: Bearer token in Authorization header.
/// Models: Hardcoded from ModelRegistry (glm-4.7, glm-4.6).
class ZhipuProvider implements AIProvider {
  @override
  String get name => 'zhipu';

  @override
  String get displayName => 'Zhipu AI (Z.AI)';

  @override
  bool get isCloud => true;

  @override
  bool get requiresApiKey => true;

  String _baseUrl = 'https://open.bigmodel.cn/api/paas';
  String? _apiKey;

  // Timeout constants
  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _defaultChatTimeout = Duration(seconds: 60);
  // Streaming timeout is handled per-request via parameter timeout

  @override
  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  /// Test connection to Zhipu AI
  ///
  /// Validates API key by calling models endpoint.
  /// Zhipu uses /v4/models endpoint for listing available models.
  @override
  Future<AIProviderError?> testConnection() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return AIProviderError.authenticationFailed;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v4/models'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
            },
          )
          .timeout(_testTimeout);

      if (response.statusCode == 200) {
        return null;
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

  /// Get list of available models from Zhipu
  ///
  /// Returns hardcoded models from ModelRegistry.
  /// Zhipu currently supports: glm-4.7 (recommended), glm-4.6.
  @override
  Future<List<String>> getAvailableModels() async {
    try {
      // Return hardcoded models from registry
      return ModelRegistry.getModelIds('zhipu');
    } catch (_) {
      return [];
    }
  }

  /// Send non-streaming chat request to Zhipu
  ///
  /// Uses OpenAI-compatible /v4/chat/completions endpoint.
  /// Request format:
  /// ```json
  /// {
  ///   "model": "glm-4.7",
  ///   "messages": [{"role": "user", "content": "..."}],
  ///   "stream": false
  /// }
  /// ```
  ///
  /// Throws [AIProviderError] on failure.
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
            Uri.parse('$_baseUrl/v4/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
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

  /// Send streaming chat request to Zhipu
  ///
  /// Returns Stream of text chunks as they are generated.
  /// Uses OpenAI-compatible SSE format:
  /// ```
  /// data: {"choices":[{"delta":{"content":"..."}}]}
  /// ```
  ///
  /// The stream completes when server sends `data: [DONE]`.
  /// Throws [AIProviderError] on connection failure.
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
        Uri.parse('$_baseUrl/v4/chat/completions'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      final responseFuture = http.Client().send(request);
      final streamedResponse = timeout == null
          ? await responseFuture
          : await responseFuture.timeout(timeout);

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
}
