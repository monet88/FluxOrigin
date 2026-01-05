# VCR Integration Tests - Implementation Status

## Task: f-x5j.2 - Create VCR Pattern Integration Tests for Flutter AI Providers

### Overview

Implemented VCR (Video Cassette Recorder) pattern integration tests for cloud AI providers in the FluxOrigin Flutter translation app. The VCR pattern records HTTP interactions with real APIs and replays them during tests, enabling:

- **Offline testing** - Tests run without network access
- **Fast execution** - No waiting for real API responses
- **Cost savings** - No repeated API calls during development
- **Deterministic results** - Same responses every time

---

## Completed Work

### 1. Package Dependency

**File**: `F:/CodeBase/FluxOrigin/pubspec.yaml`

Added `dartvcr: ^0.3.0` to `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  msix: ^3.16.0
  dartvcr: ^0.3.0  # <-- ADDED
```

---

### 2. Directory Structure Created

```
test/integration/
├── fixtures/
│   └── cassettes/          # For recorded HTTP interactions (JSON files)
├── helpers/
│   ├── vcr_test_helper.dart        # VCR utility functions
│   └── testable_ai_provider.dart   # Provider wrapper for testing
├── providers/
│   ├── openai_provider_integration_test.dart   # OpenAI tests
│   ├── gemini_provider_integration_test.dart   # Gemini tests
│   ├── deepseek_provider_integration_test.dart # DeepSeek tests
│   └── zhipu_provider_integration_test.dart    # Zhipu tests
└── README.md                # Documentation
```

---

### 3. VCR Test Infrastructure

**File**: `F:/CodeBase/FluxOrigin/test/integration/helpers/vcr_test_helper.dart`

Created VCR test helper with:
- `VCRMode` enum (record, replay, auto, bypass)
- `VCRTestHelper` class for cassette management
- Sensitive data censoring (API keys, auth tokens)
- Command-line flag parsing (`--record`, `--mock`, `--live`)

---

### 4. Provider Modification - OpenAI

**File**: `F:/CodeBase/FluxOrigin/lib/services/providers/openai_provider.dart`

Modified to support HTTP client injection:

```dart
// Added field for test client
http.Client? _testClient;

// Added setter method
void setHttpClient(http.Client client) {
  _testClient = client;
}

// Added getter for client
http.Client get _client => _testClient ?? http.Client();

// Updated all HTTP calls to use _client instead of http
// Example: await _client.get(...) instead of await http.get(...)
```

---

### 5. Integration Test - OpenAI

**File**: `F:/CodeBase/FluxOrigin/test/integration/providers/openai_provider_integration_test.dart`

Complete integration test with VCR support:
- testConnection tests
- getAvailableModels tests
- chat tests
- chatStream tests
- Error handling tests

---

### 6. Integration Tests Created (Templates)

**Files**:
- `test/integration/providers/gemini_provider_integration_test.dart`
- `test/integration/providers/deepseek_provider_integration_test.dart`
- `test/integration/providers/zhipu_provider_integration_test.dart`

These are complete test files but require the providers to be updated with HTTP client injection.

---

## Remaining Work

### Providers Needing HTTP Client Injection

The following providers need to be updated (same pattern as OpenAI):

#### 1. Gemini Provider

**File**: `F:/CodeBase/FluxOrigin/lib/services/providers/gemini_provider.dart`

Add to `GeminiProvider` class:

```dart
// After line 38 (after _apiKey field)

/// Optional HTTP client for testing (e.g., VCR recording/replay)
http.Client? _testClient;

// Update configure() method or add after it:

/// Set a custom HTTP client for testing
void setHttpClient(http.Client client) {
  _testClient = client;
}

/// Get the HTTP client to use for requests
http.Client get _client => _testClient ?? http.Client();

// Then replace:
// - Line 100: await http.post(...) -> await _client.post(...)
// - Line 154: await http.post(...) -> await _client.post(...)
// - Line 206: http.Client().send(request) -> _client.send(request)
```

#### 2. DeepSeek Provider

**File**: `F:/CodeBase/FluxOrigin/lib/services/providers/deepseek_provider.dart`

Same pattern as Gemini - add `_testClient`, `setHttpClient()`, `_client` getter, and replace HTTP calls.

#### 3. Zhipu Provider

**File**: `F:/CodeBase/FluxOrigin/lib/services/providers/zhipu_provider.dart`

Same pattern as Gemini - add `_testClient`, `setHttpClient()`, `_client` getter, and replace HTTP calls.

---

## How to Complete Remaining Providers

### Step-by-Step Instructions

For each provider (Gemini, DeepSeek, Zhipu):

1. **Add the test client field** after the `_apiKey` field:
   ```dart
   http.Client? _testClient;
   ```

2. **Add the setter method** after the `configure()` method:
   ```dart
   void setHttpClient(http.Client client) {
     _testClient = client;
   }
   ```

3. **Add the client getter** after the setter:
   ```dart
   http.Client get _client => _testClient ?? http.Client();
   ```

4. **Replace HTTP calls** throughout the file:
   - `http.get(...)` → `_client.get(...)`
   - `http.post(...)` → `_client.post(...)`
   - `http.Client()` → `_client`

5. **Run the integration tests**:
   ```bash
   # First, record cassettes (requires API key)
   flutter test test/integration/providers/gemini_provider_integration_test.dart --record

   # Then run tests in replay mode (no API key needed)
   flutter test test/integration/providers/gemini_provider_integration_test.dart --mock
   ```

---

## Usage Examples

### Record New Cassettes

```bash
# Set API key environment variable
export OPENAI_API_KEY=sk-...

# Run tests in record mode
flutter test test/integration/providers/openai_provider_integration_test.dart --record
```

### Replay Tests (Offline)

```bash
# No API key needed!
flutter test test/integration/providers/openai_provider_integration_test.dart --mock
```

### Run All Integration Tests

```bash
# Record all
flutter test test/integration --record

# Replay all
flutter test test/integration --mock
```

---

## Files Modified/Created Summary

| File | Status | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modified | Added dartvcr dependency |
| `lib/services/providers/openai_provider.dart` | Modified | Added HTTP client injection |
| `lib/services/providers/gemini_provider.dart` | TODO | Needs HTTP client injection |
| `lib/services/providers/deepseek_provider.dart` | TODO | Needs HTTP client injection |
| `lib/services/providers/zhipu_provider.dart` | TODO | Needs HTTP client injection |
| `test/integration/README.md` | Created | Documentation |
| `test/integration/helpers/vcr_test_helper.dart` | Created | VCR utilities |
| `test/integration/helpers/testable_ai_provider.dart` | Created | Provider wrapper |
| `test/integration/providers/openai_provider_integration_test.dart` | Created | OpenAI tests |
| `test/integration/providers/gemini_provider_integration_test.dart` | Created | Gemini tests (template) |
| `test/integration/providers/deepseek_provider_integration_test.dart` | Created | DeepSeek tests (template) |
| `test/integration/providers/zhipu_provider_integration_test.dart` | Created | Zhipu tests (template) |

---

## Testing the Implementation

### Verify OpenAI Tests Work

```bash
# 1. Install dependencies
flutter pub get

# 2. Record cassettes (requires API key)
export OPENAI_API_KEY=sk-...
flutter test test/integration/providers/openai_provider_integration_test.dart --record

# 3. Run tests in replay mode (no API key)
flutter test test/integration/providers/openai_provider_integration_test.dart --mock
```

### Once Other Providers Are Updated

```bash
# Record all cassettes
export GEMINI_API_KEY=...
export DEEPSEEK_API_KEY=...
export ZHIPU_API_KEY=...
flutter test test/integration --record

# Run all tests offline
flutter test test/integration --mock
```

---

## Key Implementation Details

### VCR Cassette Storage

Cassettes are stored as JSON in `test/integration/fixtures/cassettes/`:
```
openai_test_connection.json
openai_chat.json
openai_chat_stream.json
gemini_test_connection.json
...
```

### Sensitive Data Censoring

The VCR automatically censors:
- `Authorization` headers
- `x-api-key` headers
- `key`, `api_key`, `apikey` query parameters

This ensures API keys are not stored in cassette files.

### Command-Line Flags

- `--record`: Make real API calls and save responses to cassettes
- `--mock` (default): Replay recorded responses, no API calls
- `--live`: Always make real API calls, bypass cassettes

---

## Next Steps

1. **Update remaining providers** with HTTP client injection
2. **Record cassettes** for each provider (requires API keys)
3. **Commit cassette files** to repository
4. **Add CI integration** for automated testing

---

## References

- [dartvcr package](https://pub.dev/packages/dartvcr)
- [VCR pattern](https://github.com/vcr/vcr)
- [OpenAI Provider](F:/CodeBase/FluxOrigin/lib/services/providers/openai_provider.dart) - Reference implementation
