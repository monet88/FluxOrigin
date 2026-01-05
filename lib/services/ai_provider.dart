/**
 * AI Provider Abstraction Layer
 *
 * Defines the contract for all AI providers (local and cloud).
 * Each provider (Ollama, OpenAI, Gemini, etc.) implements this interface.
 */

/// Supported AI provider types
///
/// Each enum value represents a unique AI service provider.
/// Providers are categorized as local (run on user's machine) or cloud (hosted services).
enum AIProviderType {
  // Local providers - run on user's machine
  ollama,
  lmStudio,

  // Cloud providers - hosted services
  openai,
  gemini,
  deepseek,
  zhipu,

  // User-defined - any OpenAI-compatible API
  custom,
}

/// Error types that can occur during AI provider operations
///
/// Used to categorize and handle different failure scenarios
/// when communicating with AI services.
enum AIProviderError {
  /// Network unreachable or server not responding
  connectionFailed,

  /// Invalid API key or authentication credentials (401/403)
  authenticationFailed,

  /// Rate limit exceeded - too many requests (429)
  rateLimited,

  /// Requested model does not exist or is unavailable
  modelNotFound,

  /// Request exceeded time limit
  timeout,

  /// Unexpected error not covered by other types
  unknown,
}

/// Abstract interface for all AI providers
///
/// This class defines the contract that all AI providers must implement.
/// It enables the application to switch between different AI services
/// (local or cloud) without changing the core application logic.
///
/// Example usage:
/// ```dart
/// final provider = OpenAIProvider();
/// provider.configure(baseUrl: 'https://api.openai.com', apiKey: 'sk-...');
///
/// final error = await provider.testConnection();
/// if (error == null) {
///   final models = await provider.getAvailableModels();
///   final response = await provider.chat('Hello', models.first);
/// }
/// ```
abstract class AIProvider {
  /// Internal identifier for this provider (e.g., 'openai', 'ollama')
  String get name;

  /// Human-readable display name (e.g., 'OpenAI', 'Ollama Local')
  String get displayName;

  /// Whether this provider is a cloud service (true) or local (false)
  ///
  /// Cloud providers require API keys and internet connection.
  /// Local providers run on the user's machine.
  bool get isCloud;

  /// Whether this provider requires an API key for authentication
  ///
  /// Cloud providers typically return true, local providers return false.
  /// Custom provider may return false if API key is optional.
  bool get requiresApiKey;

  /// Configure this provider with base URL and optional API key
  ///
  /// Must be called before any other operations.
  ///
  /// Parameters:
  /// - [baseUrl]: The API endpoint URL (e.g., 'https://api.openai.com')
  /// - [apiKey]: Optional authentication key (required for cloud providers)
  void configure({required String baseUrl, String? apiKey});

  /// Test connection to the provider
  ///
  /// Validates that the provider is reachable and authentication works.
  /// Returns [AIProviderError] if connection fails, or `null` on success.
  ///
  /// Timeout: 5 seconds (non-configurable)
  Future<AIProviderError?> testConnection();

  /// Get list of available model IDs from this provider
  ///
  /// For cloud providers, returns hardcoded models from ModelRegistry.
  /// For local/custom providers, fetches dynamically from the server.
  ///
  /// Timeout: 10 seconds (non-configurable)
  Future<List<String>> getAvailableModels();

  /// Send a non-streaming chat request and get complete response
  ///
  /// Parameters:
  /// - [prompt]: The user's message or prompt text
  /// - [model]: Model ID to use for generation
  /// - [options]: Optional provider-specific parameters (temperature, maxTokens, etc.)
  /// - [timeout]: Optional custom timeout (default: 60 seconds)
  ///
  /// Returns the complete AI-generated response text.
  Future<String> chat(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  });

  /// Send a streaming chat request and get incremental responses
  ///
  /// Returns a Stream that yields text chunks as they are generated.
  /// Useful for real-time display of AI responses.
  ///
  /// Parameters:
  /// - [prompt]: The user's message or prompt text
  /// - [model]: Model ID to use for generation
  /// - [options]: Optional provider-specific parameters
  /// - [timeout]: Optional custom timeout (default: 120 seconds total)
  ///
  /// The stream completes when the full response is generated.
  Stream<String> chatStream(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  });
}
