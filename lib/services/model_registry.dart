/**
 * Model Registry
 *
 * Central registry of available AI models for each provider.
 * Cloud providers use hardcoded model lists. Local/custom providers
 * fetch models dynamically from their respective APIs.
 */

/// Information about a specific AI model
///
/// Contains the model identifier and user-friendly display name.
/// The [recommended] flag indicates the default/recommended model
/// for new users.
class ModelInfo {
  /// Unique model identifier used in API requests
  ///
  /// Example: 'gpt-5.2', 'gemini-3-flash', 'deepseek-chat'
  final String id;

  /// Human-readable display name for UI
  ///
  /// Example: 'GPT-5.2', 'Gemini 3 Flash'
  final String displayName;

  /// Whether this is the recommended model for new users
  ///
  /// Each provider should have at least one recommended model.
  final bool recommended;

  const ModelInfo(
    this.id,
    this.displayName, {
    this.recommended = false,
  });

  @override
  String toString() => recommended ? '$displayName ⭐' : displayName;
}

/// Central registry of AI models for all providers
///
/// Provides static access to hardcoded model lists for cloud providers.
/// Local providers (Ollama, LM Studio) and custom providers fetch
/// their models dynamically from the server.
///
/// Usage:
/// ```dart
/// final openaiModels = ModelRegistry.models['openai'];
/// final recommended = ModelRegistry.getRecommended('openai'); // gpt-5.2
/// ```
class ModelRegistry {
  /// Map of provider type to list of available models
  ///
  /// Keys match AIProviderType enum names (lowercase).
  /// Cloud providers have predefined lists. Local/custom return empty.
  static const Map<String, List<ModelInfo>> models = {
    // OpenAI models
    'openai': [
      ModelInfo('gpt-5.2', 'GPT-5.2', recommended: true),
      ModelInfo('gpt-5.2-pro', 'GPT-5.2 Pro'),
      ModelInfo('gpt-5-mini', 'GPT-5 Mini'),
      ModelInfo('gpt-4.1', 'GPT-4.1 (1M context)'),
    ],

    // Google Gemini models
    'gemini': [
      ModelInfo('gemini-3-flash', 'Gemini 3 Flash', recommended: true),
      ModelInfo('gemini-3-pro', 'Gemini 3 Pro'),
      ModelInfo('gemini-2.5-flash', 'Gemini 2.5 Flash'),
      ModelInfo('gemini-2.5-pro', 'Gemini 2.5 Pro'),
    ],

    // DeepSeek models
    'deepseek': [
      ModelInfo('deepseek-chat', 'DeepSeek Chat', recommended: true),
      ModelInfo('deepseek-reasoner', 'DeepSeek Reasoner'),
    ],

    // Zhipu (Z.AI) models
    'zhipu': [
      ModelInfo('glm-4.7', 'GLM-4.7', recommended: true),
      ModelInfo('glm-4.6', 'GLM-4.6'),
    ],

    // Local providers - fetch dynamically
    'ollama': [],
    'lmStudio': [],

    // Custom provider - fetch from user's API
    'custom': [],
  };

  /// Get the recommended model for a provider
  ///
  /// Returns the model with [recommended] flag set to true.
  /// Returns null if provider has no models or no recommended model.
  static ModelInfo? getRecommended(String providerType) {
    final providerModels = models[providerType];
    if (providerModels == null || providerModels.isEmpty) return null;

    try {
      return providerModels.firstWhere(
        (model) => model.recommended,
        orElse: () => providerModels.first,
      );
    } catch (e) {
      return providerModels.isNotEmpty ? providerModels.first : null;
    }
  }

  /// Check if a provider uses dynamic model fetching
  ///
  /// Returns true for local providers (Ollama, LM Studio) and custom.
  /// These providers fetch models from their APIs instead of using
  /// the hardcoded registry.
  static bool isDynamicProvider(String providerType) {
    return ['ollama', 'lmStudio', 'custom'].contains(providerType);
  }

  /// Get list of model IDs for a provider
  ///
  /// Convenience method to extract just the IDs from ModelInfo objects.
  static List<String> getModelIds(String providerType) {
    return models[providerType]?.map((m) => m.id).toList() ?? [];
  }

  /// Private constructor - this class is not meant to be instantiated
  ModelRegistry._();
}
