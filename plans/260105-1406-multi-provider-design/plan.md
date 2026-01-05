# Multi-Provider AI Integration Design

**Date**: 2026-01-05
**Status**: Approved
**Author**: Brainstorming Session

---

## Summary

Add support for multiple AI providers (cloud + local) with a unified abstraction layer. Users can choose between local providers (Ollama, LM Studio) and cloud providers (OpenAI, Gemini, DeepSeek, Zhipu) or connect any OpenAI-compatible API via Custom Provider.

## Requirements

| Requirement | Decision |
|-------------|----------|
| Goal | Parallel choice - users select local or cloud as they prefer |
| API Key Storage | Local (SharedPreferences, encrypted) |
| Model Selection | Hardcoded lists (cloud), fetch dynamic (local/custom) |
| Implementation | All providers at once with abstraction layer |
| Settings UI | Grouped sections: Local / Cloud / Custom |

---

## Architecture

### Provider Abstraction

```
lib/services/
├── ai_provider.dart              # Abstract interface
├── model_registry.dart           # Hardcoded model lists
├── providers/
│   ├── ollama_provider.dart      # Local - Ollama
│   ├── lm_studio_provider.dart   # Local - LM Studio
│   ├── openai_provider.dart      # Cloud - OpenAI
│   ├── gemini_provider.dart      # Cloud - Gemini
│   ├── deepseek_provider.dart    # Cloud - DeepSeek
│   ├── zhipu_provider.dart       # Cloud - Zhipu (Z.AI)
│   └── custom_provider.dart      # User-defined OpenAI-compatible
└── ai_service.dart               # Factory + orchestrator (backward compat)
```

### Abstract Interface

```dart
abstract class AIProvider {
  String get name;
  String get displayName;
  bool get isCloud;
  bool get requiresApiKey;

  Future<bool> testConnection();
  Future<List<String>> getAvailableModels();
  Future<String> chat(String prompt, String model, {Map<String, dynamic>? options});
  Stream<String> chatStream(String prompt, String model, {Map<String, dynamic>? options});
}
```

### Provider Enum

```dart
enum AIProviderType {
  // Local
  ollama,
  lmStudio,
  // Cloud
  openai,
  gemini,
  deepseek,
  zhipu,
  // User-defined
  custom,
}
```

---

## Model Registry

```dart
class ModelRegistry {
  static const Map<String, List<ModelInfo>> models = {
    'openai': [
      ModelInfo('gpt-5.2', 'GPT-5.2', recommended: true),
      ModelInfo('gpt-5.2-pro', 'GPT-5.2 Pro'),
      ModelInfo('gpt-5-mini', 'GPT-5 Mini'),
      ModelInfo('gpt-4.1', 'GPT-4.1 (1M context)'),
    ],
    'gemini': [
      ModelInfo('gemini-3-flash', 'Gemini 3 Flash', recommended: true),
      ModelInfo('gemini-3-pro', 'Gemini 3 Pro'),
      ModelInfo('gemini-2.5-flash', 'Gemini 2.5 Flash'),
      ModelInfo('gemini-2.5-pro', 'Gemini 2.5 Pro'),
    ],
    'deepseek': [
      ModelInfo('deepseek-chat', 'DeepSeek Chat', recommended: true),
      ModelInfo('deepseek-reasoner', 'DeepSeek Reasoner'),
    ],
    'zhipu': [
      ModelInfo('glm-4.7', 'GLM-4.7', recommended: true),
      ModelInfo('glm-4.6', 'GLM-4.6'),
    ],
    'custom': [], // Fetch dynamically
  };
}
```

---

## API Endpoints

| Provider | Base URL | Chat Endpoint | Auth |
|----------|----------|---------------|------|
| Ollama | `http://localhost:11434` | `/api/chat` | None |
| LM Studio | `http://localhost:1234` | `/v1/chat/completions` | None |
| OpenAI | `https://api.openai.com` | `/v1/chat/completions` | `Bearer {key}` |
| Gemini | `https://generativelanguage.googleapis.com` | `/v1beta/models/{model}:generateContent` | `?key={key}` |
| DeepSeek | `https://api.deepseek.com` | `/v1/chat/completions` | `Bearer {key}` |
| Zhipu | `https://open.bigmodel.cn/api/paas` | `/v4/chat/completions` | `Bearer {key}` |
| Custom | User-defined | `/v1/chat/completions` | Optional |

---

## Settings UI

### Layout

```
┌─────────────────────────────────────────────────────────────┐
│  ⚙️ AI Settings                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ▼ LOCAL PROVIDERS                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ○ Ollama          http://localhost:11434            │   │
│  │ ● LM Studio       http://localhost:1234   [Edit]    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ▼ CLOUD PROVIDERS                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ○ OpenAI          [Enter API Key...]                │   │
│  │ ○ Gemini          [Enter API Key...]                │   │
│  │ ○ DeepSeek        [Enter API Key...]                │   │
│  │ ○ Zhipu (Z.AI)    [Enter API Key...]                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ▼ CUSTOM PROVIDER                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ○ Custom          [OpenAI-compatible API]           │   │
│  │   URL:  [http://localhost:8317/v1          ]        │   │
│  │   Key:  [••••••••••••••] (optional)                 │   │
│  │         [Test Connection]                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  MODEL SELECTION                                            │
│  [Dropdown: Select model from chosen provider]              │
│                                                             │
│  [Save Settings]                                            │
└─────────────────────────────────────────────────────────────┘
```

### ConfigProvider Updates

```dart
// New fields for API keys
String _openaiApiKey = '';
String _geminiApiKey = '';
String _deepseekApiKey = '';
String _zhipuApiKey = '';
String _customUrl = '';
String _customApiKey = '';
```

---

## Implementation Plan

### Phase 1: Abstraction Layer
- [ ] Create `lib/services/ai_provider.dart` (abstract interface)
- [ ] Create `lib/services/model_registry.dart` (hardcoded models)

### Phase 2: Migrate Existing Providers
- [ ] Create `lib/services/providers/ollama_provider.dart`
- [ ] Create `lib/services/providers/lm_studio_provider.dart`
- [ ] Update `lib/services/ai_service.dart` (factory pattern)

### Phase 3: Cloud Providers
- [ ] Create `lib/services/providers/openai_provider.dart`
- [ ] Create `lib/services/providers/gemini_provider.dart`
- [ ] Create `lib/services/providers/deepseek_provider.dart`
- [ ] Create `lib/services/providers/zhipu_provider.dart`

### Phase 4: Custom Provider
- [ ] Create `lib/services/providers/custom_provider.dart`

### Phase 5: Settings UI
- [ ] Update `lib/ui/screens/settings_screen.dart` (grouped layout)
- [ ] Update `lib/ui/theme/config_provider.dart` (API key storage)

### Phase 6: Testing
- [ ] Test each provider connection
- [ ] Test model fetching
- [ ] Test translation with each provider

---

## File Changes Summary

| File | Action | Lines |
|------|--------|-------|
| `lib/services/ai_provider.dart` | NEW | ~50 |
| `lib/services/model_registry.dart` | NEW | ~80 |
| `lib/services/providers/ollama_provider.dart` | NEW | ~150 |
| `lib/services/providers/lm_studio_provider.dart` | NEW | ~120 |
| `lib/services/providers/openai_provider.dart` | NEW | ~120 |
| `lib/services/providers/gemini_provider.dart` | NEW | ~150 |
| `lib/services/providers/deepseek_provider.dart` | NEW | ~120 |
| `lib/services/providers/zhipu_provider.dart` | NEW | ~120 |
| `lib/services/providers/custom_provider.dart` | NEW | ~100 |
| `lib/services/ai_service.dart` | MODIFY | ~100 |
| `lib/ui/theme/config_provider.dart` | MODIFY | ~80 |
| `lib/ui/screens/settings_screen.dart` | MODIFY | ~200 |

**Total**: ~1,400 lines (9 new files, 3 modified)

---

## Error Handling

### Error Types

```dart
/// Error types for AI provider operations
enum AIProviderError {
  connectionFailed,     // Network unreachable
  authenticationFailed, // Invalid API key (401/403)
  rateLimited,          // Too many requests (429)
  modelNotFound,        // Model doesn't exist
  timeout,              // Request exceeded timeout
  unknown,              // Unexpected error
}
```

### Retry Policy

- **Max retries**: 3
- **Backoff**: Exponential (1s, 2s, 4s)
- **Retryable errors**: connectionFailed, timeout, rateLimited
- **Non-retryable**: authenticationFailed, modelNotFound

---

## Timeouts

| Operation | Timeout | Configurable |
|-----------|---------|--------------|
| testConnection | 5s | No |
| chat | 60s | Yes |
| chatStream | 120s total | Yes |
| getAvailableModels | 10s | No |

---

## Security

### API Key Storage

- **Package**: `flutter_secure_storage` (NOT plain SharedPreferences)
- **Encryption**: AES-256 (platform-native keychain/keystore)
- **Validation**: Test connection on save, show success/error feedback

---

## Testing Strategy

### Unit Tests

- Mock all providers with `MockAIProvider`
- Test error handling for each error type
- Test retry logic with simulated failures

### Integration Tests

- Use VCR pattern (recorded responses) for cloud providers
- Add `--mock` flag for development mode
- Test backward compatibility for existing Ollama/LM Studio users

### Acceptance Criteria

```gherkin
Scenario: Valid API key connection
  Given valid OpenAI API key entered
  When user clicks "Test Connection"
  Then success message shows within 5 seconds
  And model dropdown populates with available models

Scenario: Invalid API key
  Given invalid API key entered
  When user clicks "Test Connection"
  Then error message "Invalid API key" shows
  And model dropdown remains empty

Scenario: Migration from v2.0.2
  Given existing user with Ollama configured
  When app upgrades to new version
  Then Ollama settings preserved
  And app functions without reconfiguration
```

---

## Updated Interface

```dart
abstract class AIProvider {
  String get name;
  String get displayName;
  bool get isCloud;
  bool get requiresApiKey;

  /// Configure provider with URL and optional API key
  void configure({required String baseUrl, String? apiKey});

  /// Test connection, returns error type or null on success
  Future<AIProviderError?> testConnection();

  Future<List<String>> getAvailableModels();

  Future<String> chat(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  });

  Stream<String> chatStream(
    String prompt,
    String model, {
    Map<String, dynamic>? options,
    Duration? timeout,
  });
}
```

---

## Notes

- Backward compatible: existing `AIService` API unchanged
- API keys stored securely via `flutter_secure_storage`
- Custom provider supports any OpenAI-compatible API (e.g., ProxyPal at localhost:8317)
- Gemini uses different auth pattern (query param vs header) - handled internally
