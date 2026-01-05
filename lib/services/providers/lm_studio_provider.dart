import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';

/// LM Studio Local AI Provider
///
/// Implements AIProvider for LM Studio local server.
/// LM Studio uses OpenAI-compatible API format.
/// Runs locally on http://localhost:1234 by default.
class LMStudioProvider implements AIProvider {
  @override
  String get name => 'lmStudio';

  @override
  String get displayName => 'LM Studio (Local)';

  @override
  bool get isCloud => false;

  @override
  bool get requiresApiKey => false;

  String _baseUrl = 'http://localhost:1234';
  // ignore: unused_field
  String? _apiKey;

  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _defaultChatTimeout = Duration(seconds: 60);
  static const Duration _modelsTimeout = Duration(seconds: 10);

  @override
  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  @override
  Future<AIProviderError?> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/models'),
          )
          .timeout(_testTimeout);

      if (response.statusCode == 200) {
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
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/models'),
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
            headers: {'Content-Type': 'application/json'},
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
      request.headers['Content-Type'] = 'application/json';
      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      final responseFuture = http.Client().send(request);
      final streamedResponse = timeout == null
          ? await responseFuture
          : await responseFuture.timeout(timeout);

      if (streamedResponse.statusCode != 200) {
        if (streamedResponse.statusCode == 404) {
          throw AIProviderError.modelNotFound;
        } else {
          throw AIProviderError.connectionFailed;
        }
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
          // Skip invalid JSON
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
