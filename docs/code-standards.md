# FluxOrigin - Code Standards & Conventions

## Overview

This document defines the coding standards, architectural patterns, and best practices for the FluxOrigin codebase. All contributors must follow these guidelines to maintain code quality and consistency.

## File Organization

### Directory Structure
```
lib/
├── controllers/          # Business logic controllers
├── models/              # Data models (JSON serializable)
├── services/            # External service integrations (AI, web, logging)
├── ui/                  # User interface layer
│   ├── screens/         # Full-page screens
│   ├── widgets/         # Reusable UI components
│   └── theme/           # Theme configuration and providers
└── utils/               # Utility functions (parsing, processing, i18n)
```

### File Naming Conventions

**Rule:** `snake_case` for all Dart files

✅ **Correct:**
- `translation_controller.dart`
- `ai_service.dart`
- `file_upload_zone.dart`
- `ollama_health_check.dart`

❌ **Incorrect:**
- `TranslationController.dart`
- `AIService.dart`
- `FileUploadZone.dart`

**Class Names:** `PascalCase` (standard Dart convention)
```dart
class TranslationController { }
class AIService { }
class FileUploadZone extends StatelessWidget { }
```

## Code Documentation Standards

### File Headers
Every file must include a top-level comment describing its purpose:

```dart
/// Translation controller managing the AI-powered translation pipeline.
///
/// Handles file parsing, chunking, glossary application, and resume capability.
/// Coordinates between AIService and TextProcessor to translate documents
/// while maintaining context across chunk boundaries.
```

### Class Documentation
```dart
/// Manages connection and API calls to AI providers (Ollama, LM Studio).
///
/// Supports dual-provider abstraction with automatic endpoint resolution,
/// connection health checks, and anti-hallucination response cleaning.
class AIService {
  // ...
}
```

### Method Documentation
Use doc comments (`///`) for public methods:

```dart
/// Translates a file with resume capability.
///
/// Parameters:
/// - [filePath]: Absolute path to source file (TXT or EPUB)
/// - [sourceLang]: Source language code (e.g., 'en', 'vi')
/// - [targetLang]: Target language code
/// - [dictionaryDir]: Directory containing glossary CSV files
/// - [onUpdate]: Callback for status messages and progress (0.0-1.0)
/// - [onChunkUpdate]: Callback for live chunk preview (index, total, source, translated)
/// - [resume]: If true and progress exists, resume from saved state
///
/// Returns the translated content as a String, or null if paused.
Future<String?> translateFile({
  required String filePath,
  required String sourceLang,
  required String targetLang,
  required String dictionaryDir,
  Function(String, double)? onUpdate,
  Function(int, int, String, String)? onChunkUpdate,
  bool resume = false,
}) async {
  // ...
}
```

### Inline Comments
Use `//` for logic explanations:

```dart
// Split text at sentence boundaries to preserve context
final chunks = TextProcessor.smartSplit(fullText);

// Load existing progress or create new state
final progress = await TranslationProgress.loadFromFile(progressPath)
    ?? TranslationProgress(/* ... */);

// Skip already translated chunks (resume behavior)
for (int i = progress.currentIndex; i < rawChunks.length; i++) {
  // ...
}
```

## Flutter & Dart Best Practices

### State Management
**Pattern:** Provider with ChangeNotifier

```dart
// Theme state management
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners(); // Always notify after state change
  }
}

// Usage in main.dart
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ChangeNotifierProvider(create: (_) => ConfigProvider()),
    ],
    child: const MyApp(),
  ),
);

// Consumption in widgets
final themeNotifier = Provider.of<ThemeNotifier>(context);
```

### Widget Structure
**Prefer StatelessWidget** unless state is essential:

```dart
class FileUploadZone extends StatelessWidget {
  final Function(String) onFileSelected;
  final bool isEnabled;

  const FileUploadZone({
    Key? key,
    required this.onFileSelected,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DesktopDrop(
      onDrop: (details) => _handleDrop(details),
      child: _buildDropZone(context),
    );
  }
}
```

**Use StatefulWidget** for local UI state:

```dart
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  bool _isTranslating = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

### Async/Await Pattern
**Always use try-catch** for async operations:

```dart
Future<void> _startTranslation() async {
  setState(() => _isTranslating = true);

  try {
    final result = await _controller.translateFile(
      filePath: _selectedFile!,
      sourceLang: _sourceLang,
      targetLang: _targetLang,
      onUpdate: (status, progress) {
        setState(() {
          _statusMessage = status;
          _progress = progress;
        });
      },
    );

    if (result != null) {
      _showSuccessDialog(result);
    }
  } catch (e) {
    _logger.error('TranslateScreen', 'Translation failed: $e');
    _showErrorDialog(e.toString());
  } finally {
    setState(() => _isTranslating = false);
  }
}
```

### Null Safety
**Leverage Dart's sound null safety:**

```dart
// Use late for delayed initialization
class AIService {
  late final DevLogger _logger;

  AIService() {
    _logger = DevLogger();
  }
}

// Use ? for nullable types
String? _selectedFile;
Function(String, double)? onUpdate;

// Use ?? for default values
final baseUrl = url ?? _defaultBaseUrl;

// Use ?. for safe navigation
final modelCount = response.data?.length ?? 0;

// Use ! only when 100% certain (prefer guards)
if (_selectedFile != null) {
  final file = File(_selectedFile!); // Safe because of guard
}
```

## Error Handling

### Service Layer
**Return tuples or custom result types:**

```dart
/// Returns (success, errorCode, modelCount)
Future<(bool, String?, int)> checkConnection() async {
  try {
    final response = await http.get(Uri.parse(modelsEndpoint))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (true, null, data['models'].length);
    } else {
      return (false, 'error_status:${response.statusCode}', 0);
    }
  } on http.ClientException {
    return (false, 'error_connect', 0);
  } catch (e) {
    if (e.toString().contains('TimeoutException')) {
      return (false, 'error_timeout', 0);
    }
    return (false, 'error_generic', 0);
  }
}
```

### UI Layer
**Show user-friendly error messages:**

```dart
void _handleConnectionError(String? errorCode) {
  String message;
  switch (errorCode) {
    case 'error_connect':
      message = AppStrings.get('error_ollama_connect');
      break;
    case 'error_timeout':
      message = AppStrings.get('error_ollama_timeout');
      break;
    default:
      message = AppStrings.get('error_generic');
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

### Logging
**Use centralized DevLogger:**

```dart
final DevLogger _logger = DevLogger();

_logger.info('AIService', 'Base URL set to: $normalizedUrl');
_logger.error('TranslationController', 'Failed to parse file: $e');
_logger.warning('HealthCheck', 'Connection unstable, retrying...');
```

## Internationalization (i18n)

### String Management
**All UI strings in `app_strings.dart`:**

```dart
class AppStrings {
  static String _language = 'vi'; // Default Vietnamese

  static final Map<String, Map<String, String>> _strings = {
    'app_title': {'vi': 'FluxOrigin', 'en': 'FluxOrigin'},
    'translate_screen_title': {'vi': 'Dịch Tài Liệu', 'en': 'Translate'},
    'error_file_not_found': {
      'vi': 'Không tìm thấy tệp',
      'en': 'File not found'
    },
  };

  static String get(String key) {
    return _strings[key]?[_language] ?? key;
  }

  static void setLanguage(String lang) {
    _language = lang;
  }
}
```

### Usage in Widgets
```dart
Text(AppStrings.get('translate_screen_title'))
```

**Never hardcode UI strings:**

❌ **Incorrect:**
```dart
Text('Dịch Tài Liệu')
```

✅ **Correct:**
```dart
Text(AppStrings.get('translate_screen_title'))
```

## JSON Serialization

### Model Classes
**Use manual JSON serialization (no code generation in this project):**

```dart
class TranslationProgress {
  final String fileName;
  final String sourceLang;
  final String targetLang;
  final List<String> rawChunks;
  final List<String> translatedChunks;
  int currentIndex;

  TranslationProgress({
    required this.fileName,
    required this.sourceLang,
    required this.targetLang,
    required this.rawChunks,
    required this.translatedChunks,
    this.currentIndex = 0,
  });

  // Serialize to JSON
  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'sourceLang': sourceLang,
    'targetLang': targetLang,
    'rawChunks': rawChunks,
    'translatedChunks': translatedChunks,
    'currentIndex': currentIndex,
  };

  // Deserialize from JSON
  factory TranslationProgress.fromJson(Map<String, dynamic> json) {
    return TranslationProgress(
      fileName: json['fileName'] as String,
      sourceLang: json['sourceLang'] as String,
      targetLang: json['targetLang'] as String,
      rawChunks: List<String>.from(json['rawChunks']),
      translatedChunks: List<String>.from(json['translatedChunks']),
      currentIndex: json['currentIndex'] as int,
    );
  }

  // File I/O helpers
  Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.writeAsString(jsonEncode(toJson()));
  }

  static Future<TranslationProgress?> loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    final json = jsonDecode(content);
    return TranslationProgress.fromJson(json);
  }
}
```

## Performance Guidelines

### Avoid Blocking UI Thread
```dart
// Use compute() for heavy processing
final chunks = await compute(TextProcessor.smartSplit, largeText);

// Or use isolates for long-running tasks
final result = await Isolate.run(() => _processLargeFile(filePath));
```

### Efficient List Operations
```dart
// Use whereType for safe filtering
final validModels = data['models'].whereType<Map<String, dynamic>>().toList();

// Use map for transformations
final modelNames = models.map((m) => m['name'] as String).toList();
```

### Memory Management
```dart
// Dispose controllers in StatefulWidget
@override
void dispose() {
  _textController.dispose();
  _scrollController.dispose();
  super.dispose();
}

// Close streams
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

## Testing Standards

### Unit Tests
Located in `test/` directory:

```dart
void main() {
  group('TextProcessor', () {
    test('smartSplit preserves sentence boundaries', () {
      final text = 'First sentence. Second sentence. Third sentence.';
      final chunks = TextProcessor.smartSplit(text, targetSize: 20);

      expect(chunks.length, greaterThan(1));
      expect(chunks.every((c) => c.endsWith('.')), isTrue);
    });
  });
}
```

### Widget Tests
```dart
void main() {
  testWidgets('FileUploadZone displays drop text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileUploadZone(onFileSelected: (_) {}),
        ),
      ),
    );

    expect(find.text(AppStrings.get('upload_hint')), findsOneWidget);
  });
}
```

## Code Review Checklist

Before committing code, ensure:

- [ ] All files follow `snake_case` naming
- [ ] Public APIs have doc comments (`///`)
- [ ] Complex logic has inline comments (`//`)
- [ ] Error handling uses try-catch
- [ ] No hardcoded UI strings (use `AppStrings`)
- [ ] Null safety rules followed (no unsafe `!` usage)
- [ ] State management uses Provider pattern
- [ ] Async operations have timeouts
- [ ] Resources disposed in `dispose()` methods
- [ ] Code formatted with `dart format`
- [ ] No linter warnings (`flutter analyze`)

## Common Patterns

### Singleton Services
```dart
class DevLogger {
  static final DevLogger _instance = DevLogger._internal();
  factory DevLogger() => _instance;
  DevLogger._internal();

  final List<String> _logs = [];
  // ...
}
```

### Callback Pattern
```dart
typedef ProgressCallback = void Function(String status, double progress);
typedef ChunkCallback = void Function(int index, int total, String source, String translated);

Future<void> processWithCallbacks({
  required ProgressCallback onProgress,
  required ChunkCallback onChunk,
}) async {
  // ...
  onProgress('Processing chunk 1/10', 0.1);
  onChunk(0, 10, sourceText, translatedText);
}
```

---

**Document Version:** 1.0
**Last Updated:** 2026-01-04
**Compliance:** Dart 3.x, Flutter 3.x
