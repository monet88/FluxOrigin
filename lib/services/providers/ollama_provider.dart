import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_provider.dart';

/// Ollama Local AI Provider
///
/// Implements AIProvider for Ollama local server.
/// Ollama runs locally on http://localhost:11434 by default.
/// No authentication required.
class OllamaProvider implements AIProvider {
  /// Internal identifier
  @override
  String get name => 'ollama';

  /// Display name for UI
  @override
  String get displayName => 'Ollama (Local)';

  /// Local provider, not cloud
  @override
  bool get isCloud => false;

  /// No API key required for local Ollama
  @override
  bool get requiresApiKey => false;

  /// Configured base URL (default: http://localhost:11434)
  String _baseUrl = 'http://localhost:11434';

  /// Optional API key (not used by Ollama, but stored for interface consistency)
  // ignore: unused_field
  String? _apiKey;

  /// Timeout constants
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
            Uri.parse('$_baseUrl/api/tags'),
          )
          .timeout(_testTimeout);

      if (response.statusCode == 200) {
        return null; // Success
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
            Uri.parse('$_baseUrl/api/tags'),
          )
          .timeout(_modelsTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final models = json['models'] as List<dynamic>?;
        if (models != null) {
          return models
              .map((m) => m['name'] as String)
              .toList()
            ..sort(); // Return sorted list for consistent UI
        }
      }
      return [];
    } catch (e) {
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
        'prompt': prompt,
        'stream': false,
        if (options != null) ...options,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout ?? _defaultChatTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Ollama returns response in 'message' -> 'content' or 'response'
        final message = json['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null) {
          return content;
        }
        // Fallback to direct 'response' field (older Ollama versions)
        return json['response'] as String? ?? '';
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
    // Create a controller for the stream
    final controller = StreamController<String>();

    try {
      final requestBody = {
        'model': model,
        'prompt': prompt,
        'stream': true,
        if (options != null) ...options,
      };

      final request = http.StreamedRequest(
        'POST',
        Uri.parse('$_baseUrl/api/chat'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.sink.add(utf8.encode(jsonEncode(requestBody)));

      // Set timeout wrapper
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

      // Parse Server-Sent Events (SSE)
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isEmpty) continue;

        try {
          final json = jsonDecode(line) as Map<String, dynamic>;

          // Check for errors
          if (json.containsKey('error')) {
            controller.addError(AIProviderError.unknown);
            break;
          }

          // Check if done
          final done = json['done'] as bool?;
          if (done == true) {
            break;
          }

          // Extract content from response
          final message = json['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            controller.add(content);
          }
        } catch (_) {
          // Skip invalid JSON lines
        }
      }
    } on TimeoutException {
      controller.addError(AIProviderError.timeout);
    } on SocketException {
      controller.addError(AIProviderError.connectionFailed);
    } on AIProviderError catch (e) {
      controller.addError(e);
    } catch (e) {
      controller.addError(AIProviderError.unknown);
    } finally {
      await controller.close();
    }

    // Yield all buffered content
    yield* controller.stream;
  }
}
