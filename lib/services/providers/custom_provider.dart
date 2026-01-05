import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';

/// Custom OpenAI-Compatible API Provider
///
/// Implements AIProvider for user-defined OpenAI-compatible endpoints.
/// Supports any service using the OpenAI API format (ProxyPal, local servers, etc.).
///
/// Features:
/// - User-defined base URL (configured via `configure()`)
/// - Optional API key authentication (Bearer token)
/// - Dynamic model fetching from `/v1/models` endpoint
/// - Non-streaming and streaming chat support
/// - Standard OpenAI error format handling
class CustomProvider implements AIProvider {
  @override
  String get name => 'custom';

  @override
  String get displayName => 'Custom (OpenAI-Compatible)';

  @override
  bool get isCloud => false;

  @override
  bool get requiresApiKey => false;

  /// Base URL for the custom API endpoint (e.g., 'https://api.example.com')
  String _baseUrl = '';

  /// Optional API key for Bearer token authentication
  /// If null or empty, no Authorization header is sent
  String? _apiKey;

  /// Timeout for connection testing
  static const Duration _testTimeout = Duration(seconds: 5);

  /// Timeout for fetching available models
  static const Duration _modelsTimeout = Duration(seconds: 10);

  /// Default timeout for non-streaming chat requests
  static const Duration _defaultChatTimeout = Duration(seconds: 60);

  /// Default timeout for streaming chat requests
  static const Duration _defaultStreamTimeout = Duration(seconds: 120);

  @override
  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  /// Build HTTP headers with optional Authorization
  ///
  /// Only includes Authorization header if apiKey is not null/empty.
  Map<String, String> _buildHeaders() {
    final headers = {'Content-Type': 'application/json'};

    // Only add Authorization if apiKey is provided and not empty
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }

    return headers;
  }

  @override
  Future<AIProviderError?> testConnection() async {
    if (_baseUrl.isEmpty) {
      return AIProviderError.connectionFailed;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/models'),
            headers: _apiKey != null && _apiKey!.isNotEmpty
                ? {'Authorization': 'Bearer $_apiKey'}
                : null,
          )
          .timeout(_testTimeout);

      if (response.statusCode == 200 || response.statusCode == 401) {
        // 401 means server is reachable but auth failed - connection is valid
        return null;
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
    if (_baseUrl.isEmpty) {
      return [];
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/models'),
            headers: _apiKey != null && _apiKey!.isNotEmpty
                ? {'Authorization': 'Bearer $_apiKey'}
                : null,
          )
          .timeout(_modelsTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>?;
        if (data != null) {
          return data
              .map((m) => m['id'] as String)
              .toList()
            ..sort();
        }
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
    if (_baseUrl.isEmpty) {
      throw AIProviderError.connectionFailed;
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
    if (_baseUrl.isEmpty) {
      throw AIProviderError.connectionFailed;
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

      // Set headers
      request.headers['Content-Type'] = 'application/json';
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_apiKey';
      }

      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      final responseFuture = http.Client().send(request);
      final streamedResponse = timeout == null
          ? await responseFuture.timeout(_defaultStreamTimeout)
          : await responseFuture.timeout(timeout);

      if (streamedResponse.statusCode == 401 || streamedResponse.statusCode == 403) {
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

      // Parse SSE (OpenAI format)
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
