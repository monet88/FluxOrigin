# VCR Integration Tests for Flutter AI Providers

## Overview

This directory contains integration tests for cloud AI providers using the VCR (Video Cassette Recorder) pattern. Tests record HTTP interactions with real APIs and replay them later, enabling:

- **Offline testing** - Run tests without network access
- **Fast execution** - No waiting for real API responses
- **Cost savings** - No repeated API calls during development
- **Deterministic results** - Same responses every time

## Architecture

```
test/integration/
├── fixtures/
│   └── cassettes/          # Recorded HTTP interactions (JSON files)
├── helpers/
│   ├── vcr_test_helper.dart     # VCR utility functions
│   └── testable_ai_provider.dart # Provider wrapper for testing
└── providers/
    ├── openai_provider_integration_test.dart  # OpenAI tests (template)
    ├── gemini_provider_integration_test.dart  # Gemini tests
    ├── deepseek_provider_integration_test.dart # DeepSeek tests
    └── zhipu_provider_integration_test.dart   # Zhipu tests
```

## Prerequisites

### Required Package

`dartvcr: ^0.3.0` is added to `dev_dependencies` in `pubspec.yaml`.

Run `flutter pub get` to install dependencies.

### API Keys for Recording

To **record** new cassettes, set these environment variables:

```bash
export OPENAI_API_KEY=sk-...
export GEMINI_API_KEY=...
export DEEPSEEK_API_KEY=sk-...
export ZHIPU_API_KEY=...
```

**No API keys needed** for replay mode!

## Usage

### Record Mode (First Time)

Records actual API calls to cassettes:

```bash
# Record OpenAI tests
flutter test test/integration/providers/openai_provider_integration_test.dart --record

# Record all tests
flutter test test/integration --record
```

### Replay Mode (Default)

Uses recorded cassettes, no API calls:

```bash
# Replay OpenAI tests
flutter test test/integration/providers/openai_provider_integration_test.dart --mock

# Replay all tests
flutter test test/integration --mock
```

### Live Mode (Always Real API)

Bypasses cassettes, always makes real API calls:

```bash
flutter test test/integration --live
```

## Provider Modification Required

To enable VCR testing, each provider needs HTTP client injection support.

### Changes Required

Add to each provider class (`OpenAIProvider`, `GeminiProvider`, etc.):

```dart
// 1. Add field for test client
http.Client? _testClient;

// 2. Add setter method
void setHttpClient(http.Client client) {
  _testClient = client;
}

// 3. Add getter for client
http.Client get _client => _testClient ?? http.Client();

// 4. Replace http.get() with _client.get()
// Replace http.post() with _client.post()
// Replace http.Client() with _client
```

### Example: OpenAI Provider

`lib/services/providers/openai_provider.dart` has been updated with:
- `setHttpClient()` method for test client injection
- `_client` getter that returns test client or default
- All HTTP calls use `_client` instead of `http` functions

## Creating New Integration Tests

### Template

Copy `openai_provider_integration_test.dart` and modify:

```dart
// 1. Update VCR mode getter (if different)
// 2. Update _getApiKey() for provider's env variable
// 3. Update provider instantiation
provider = GeminiProvider(); // instead of OpenAIProvider()

// 4. Update cassette names
cassette = Cassette(cassettesDir, 'gemini_test_connection');

// 5. Update test data (models, endpoints, etc.)
const model = 'gemini-2-flash'; // instead of 'gpt-4o-mini'
```

## Cassette Files

Cassettes are stored as JSON in `test/integration/fixtures/cassettes/`:

```
openai_test_connection.json
openai_chat.json
openai_chat_stream.json
gemini_test_connection.json
gemini_chat.json
...
```

### Sensitive Data Handling

Cassettes automatically censor:
- `Authorization` headers
- `x-api-key` headers
- `key`, `api_key`, `apikey` query parameters

## Test Coverage

Each provider integration test should cover:

### Basic Tests
- ✅ `testConnection` with valid API key
- ✅ `testConnection` with invalid API key (record mode only)
- ✅ `getAvailableModels` returns model list
- ✅ `chat` returns response for simple prompt
- ✅ `chatStream` streams response chunks

### Advanced Tests (Optional)
- Error handling (invalid model, rate limits, etc.)
- Options (temperature, maxTokens, etc.)
- Timeout behavior
- Streaming completion

## Troubleshooting

### "Missing API key" Error

**Cause**: Running in record/live mode without API key set.

**Fix**: Set environment variable or use replay mode:
```bash
export OPENAI_API_KEY=sk-...
# or
flutter test test/integration --mock
```

### "No matching recording found" Error

**Cause**: Request doesn't match any recorded interaction.

**Fix**:
1. Re-record the cassette with `--record`
2. Ensure request parameters match exactly
3. Check cassette file exists

### Tests Pass in Record Mode but Fail in Replay

**Cause**: Non-deterministic API responses (timestamps, random values, etc.)

**Fix**:
1. Use deterministic test prompts
2. Avoid testing values that change (timestamps, IDs)
3. Use response validation instead of exact matching

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Run integration tests (replay mode)
        run: flutter test test/integration --mock
```

### Recording New Cassettes in CI

```yaml
# Manual workflow for recording
name: Record Cassettes

on:
  workflow_dispatch:

jobs:
  record:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Record cassettes
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: flutter test test/integration --record
      - name: Upload cassettes
        uses: actions/upload-artifact@v3
        with:
          name: cassettes
          path: test/integration/fixtures/cassettes/
```

## Implementation Status

### Completed
- ✅ `dartvcr` package added to `pubspec.yaml`
- ✅ `test/integration/` directory structure created
- ✅ VCR test helper utilities created
- ✅ OpenAI provider updated with HTTP client injection
- ✅ OpenAI integration tests created

### TODO
- ⏳ Update Gemini provider with HTTP client injection
- ⏳ Create Gemini integration tests
- ⏳ Update DeepSeek provider with HTTP client injection
- ⏳ Create DeepSeek integration tests
- ⏳ Update Zhipu provider with HTTP client injection
- ⏳ Create Zhipu integration tests

## References

- [dartvcr package documentation](https://pub.dev/packages/dartvcr)
- [VCR pattern (Ruby VCR)](https://github.com/vcr/vcr)
- [HTTP testing best practices](https://dart.dev/guides/testing/json#fixed-test-data)
