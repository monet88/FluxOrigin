import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';
import '../model_registry.dart';

/// OpenAI Cloud Provider
///
/// Implements AIProvider for OpenAI API (https://api.openai.com).
/// Requires API key for authentication (Bearer token).
/// Uses OpenAI-compatible API format with messages array.
class OpenAIProvider implements AIProvider {
  @override
  String get name => 'openai';

  @override
  String get displayName => 'OpenAI';

  @override
  bool get isCloud => true;

  @override
  bool get requiresApiKey => true;

  /// Configured base URL (default: https://api.openai.com)
  String _baseUrl = 'https://api.openai.com';

  /// API key for Bearer authentication
  String? _apiKey;

  // Timeout constants
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
            headers: {'Authorization': 'Bearer $_apiKey'},
          )
          .timeout(_testTimeout);

      // Map HTTP status to AIProviderError
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
    // Return hardcoded models from ModelRegistry
    // OpenAI models are predefined, not fetched dynamically
    final modelInfos = ModelRegistry.models['openai'] ?? [];
    return modelInfos.map((m) => m.id).toList()..sort();
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
      // Build request body with OpenAI format
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
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout ?? _defaultChatTimeout);

      // Map HTTP status to AIProviderError
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
      } else if (response.statusCode == 429) {
        throw AIProviderError.rateLimited;
      } else if (response.statusCode == 404) {
        throw AIProviderError.modelNotFound;
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
    } catch (e) {
      // Check for model-specific error in response body
      if (e is http.ClientException) {
        throw AIProviderError.connectionFailed;
      }
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
      // Build request body for streaming
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
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      // Send with timeout
      final responseFuture = http.Client().send(request);
      final streamedResponse = timeout == null
          ? await responseFuture.timeout(_defaultChatStreamTimeout)
          : await responseFuture.timeout(timeout);

      // Map HTTP status to AIProviderError
      if (streamedResponse.statusCode == 401 ||
          streamedResponse.statusCode == 403) {
        throw AIProviderError.authenticationFailed;
      } else if (streamedResponse.statusCode == 429) {
        throw AIProviderError.rateLimited;
      } else if (streamedResponse.statusCode == 404) {
        throw AIProviderError.modelNotFound;
      } else if (streamedResponse.statusCode >= 500) {
        throw AIProviderError.connectionFailed;
      } else if (streamedResponse.statusCode != 200) {
        throw AIProviderError.unknown;
      }

      // Parse Server-Sent Events (SSE) - OpenAI format
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

          // Check for error response
          if (json.containsKey('error')) {
            final error = json['error'] as Map<String, dynamic>?;
            final code = error?['code'] as String?;
            if (code == 'invalid_api_key' || code == 'insufficient_quota') {
              throw AIProviderError.authenticationFailed;
            } else if (code == 'rate_limit_exceeded') {
              throw AIProviderError.rateLimited;
            } else if (code == 'model_not_found') {
              throw AIProviderError.modelNotFound;
            }
            throw AIProviderError.unknown;
          }

          // Extract content from delta
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {
          // Skip invalid JSON lines (non-error cases)
        }
      }
    } on TimeoutException {
      throw AIProviderError.timeout;
    } on SocketException {
      throw AIProviderError.connectionFailed;
    } on AIProviderError {
      rethrow;
    } catch (e) {
      throw AIProviderError.unknown;
    }
  }
}
