# FluxOrigin - Codebase Summary

## Repository Overview

**FluxOrigin** is a Windows desktop application for AI-powered book translation, built with Flutter/Dart. The codebase consists of 74 tracked files (120K tokens, 556K chars) organized into a clean layered architecture.

**Key Statistics:**
- **Version:** 2.0.2+1
- **Dart Files:** 25 (core application logic)
- **Tests:** 4 test files
- **Lines of Code:** ~6,000+ (excluding tests and generated files)
- **Primary Language:** Dart 3.x with Flutter 3.x

## Directory Structure

```
FluxOrigin/
├── .beads/                      # Beads issue tracking integration
│   ├── config.yaml              # Beads configuration
│   ├── interactions.jsonl       # Issue interactions log
│   ├── metadata.json            # Repository metadata
│   └── README.md                # Beads documentation
│
├── .github/
│   └── CODEOWNERS               # Code ownership rules
│
├── .kiro/
│   └── settings/mcp.json        # MCP server configuration
│
├── assets/
│   ├── fluxorigin_logo.png      # Application logo (primary)
│   └── fluxorigin logo.png      # Alternative logo
│
├── docs/                        # Documentation (this directory)
│   ├── project-overview-pdr.md  # Product Development Requirements
│   ├── code-standards.md        # Coding conventions
│   ├── system-architecture.md   # Architecture documentation
│   └── codebase-summary.md      # This file
│
├── installers/
│   └── Flux_Origin.iss          # Inno Setup installer script
│
├── lib/                         # Main application code (25 files)
│   ├── controllers/             # Business logic layer
│   │   └── translation_controller.dart  # Translation pipeline orchestrator (564 lines)
│   │
│   ├── models/                  # Data models
│   │   └── translation_progress.dart    # JSON-serializable progress state
│   │
│   ├── services/                # External integrations
│   │   ├── ai_service.dart      # AI provider abstraction (774 lines)
│   │   ├── web_search_service.dart      # RAG glossary enrichment
│   │   └── dev_logger.dart      # Centralized logging service
│   │
│   ├── ui/                      # User interface layer
│   │   ├── app.dart             # Root MaterialApp, navigation setup
│   │   │
│   │   ├── screens/             # Full-page screens (5 files)
│   │   │   ├── translate_screen.dart    # Main translation UI (8,217 tokens)
│   │   │   ├── history_screen.dart      # Translation history viewer
│   │   │   ├── dictionary_screen.dart   # Glossary management
│   │   │   ├── settings_screen.dart     # Configuration UI (10,084 tokens)
│   │   │   └── dev_logs_screen.dart     # Debug console
│   │   │
│   │   ├── widgets/             # Reusable components (9 files)
│   │   │   ├── file_upload_zone.dart           # Drag-drop file selector
│   │   │   ├── language_selector.dart          # Language dropdown
│   │   │   ├── ollama_connection_dialog.dart   # Error dialog
│   │   │   ├── ollama_health_check.dart        # Background AI monitor
│   │   │   ├── path_setup_modal.dart           # First-run setup
│   │   │   ├── sidebar_item.dart               # Navigation item
│   │   │   ├── sidebar.dart                    # Navigation sidebar
│   │   │   ├── title_bar.dart                  # Custom window title bar
│   │   │   └── upload_dictionary_modal.dart    # CSV upload modal
│   │   │
│   │   └── theme/               # Theme configuration
│   │       ├── app_theme.dart   # Light/Dark themes, ThemeNotifier
│   │       └── config_provider.dart  # Global config state
│   │
│   ├── utils/                   # Utility functions
│   │   ├── app_strings.dart     # i18n strings (~170 entries, Vietnamese + English)
│   │   ├── file_parser.dart     # TXT/EPUB text extraction
│   │   └── text_processor.dart  # Smart chunking, context extraction (205 lines)
│   │
│   └── main.dart                # Application entry point, window setup
│
├── plans/                       # Planning documents
│   └── reports/                 # Scout agent reports
│       ├── scout-external-260104-2319-documentation-audit.md
│       ├── scout-external-260104-2319-lib-structure.md
│       └── scout-external-260104-2319-project-structure.md
│
├── test/                        # Test files
│   ├── ai_service_refactor_test.dart   # AIService unit tests
│   ├── text_processor_test.dart        # TextProcessor unit tests
│   ├── verify_web_search.dart          # Web search integration test
│   └── widget_test.dart                # Placeholder widget test
│
├── windows/                     # Windows platform code
│   ├── runner/                  # Native Windows app wrapper
│   │   ├── main.cpp             # Win32 entry point
│   │   ├── flutter_window.cpp   # Flutter view integration
│   │   ├── win32_window.cpp     # Window management
│   │   └── resources/app_icon.ico  # Application icon
│   └── CMakeLists.txt           # Build configuration
│
├── .gitignore                   # Git ignore rules
├── .metadata                    # Flutter metadata
├── analysis_options.yaml        # Dart linter configuration
├── AGENTS.md                    # Agent workflow documentation
├── LICENSE                      # GPLv3 license (7,526 tokens)
├── PRIVACY.md                   # Privacy policy
├── pubspec.yaml                 # Dart package dependencies
├── pubspec.lock                 # Locked dependency versions (7,502 tokens)
├── README.md                    # Project README
└── ui_design.html               # UI design mockup (10,693 tokens)
```

## Core Application Files (lib/)

### Entry Points (2 files)

#### `main.dart` (42 lines)
**Purpose:** Application bootstrap and initialization

**Key Responsibilities:**
- Initialize Flutter bindings
- Configure window manager (size: 1000x700, min: 800x600)
- Set up Provider state management (ThemeNotifier, ConfigProvider)
- Hide native title bar (custom title bar used)

**Critical Code:**
```dart
await windowManager.ensureInitialized();
const windowOptions = WindowOptions(
  titleBarStyle: TitleBarStyle.hidden,  // Custom title bar
);
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ChangeNotifierProvider(create: (_) => ConfigProvider()),
    ],
    child: const MyApp(),
  ),
);
```

#### `ui/app.dart`
**Purpose:** Root MaterialApp configuration

**Key Responsibilities:**
- Set up theme (light/dark) from ThemeNotifier
- Configure IndexedStack navigation (5 screens)
- Implement sidebar-based screen switching

### Controllers (1 file)

#### `controllers/translation_controller.dart` (564 lines)
**Purpose:** Orchestrates the entire translation pipeline

**Key Features:**
- Resume-capable translation (saves after each chunk)
- Context-aware chunking (passes 200 chars from previous chunk)
- Pause/resume functionality
- Progress tracking and persistence
- Coordinates AIService, TextProcessor, FileParser

**Public API:**
```dart
Future<String?> translateFile({...})  // Main translation entry point
Future<bool> hasProgress(String filePath, String dictionaryDir)
Future<double?> getProgressPercentage(String filePath, String dictionaryDir)
void requestPause()  // User pause request
void resetPause()    // Reset before start/resume
```

**Dependencies:**
- AIService (AI calls)
- WebSearchService (optional RAG enrichment)
- TextProcessor (chunking)
- FileParser (TXT/EPUB parsing)
- DevLogger (logging)

### Models (1 file)

#### `models/translation_progress.dart`
**Purpose:** JSON-serializable progress state

**Schema:**
```dart
{
  "fileName": String,
  "sourceLang": String,
  "targetLang": String,
  "rawChunks": List<String>,
  "translatedChunks": List<String>,
  "currentIndex": int,
  "genreDetected": String,
  "glossary": Map<String, String>
}
```

**Methods:**
- `toJson()` - Serialize to JSON
- `fromJson()` - Deserialize from JSON
- `saveToFile()` - Write to `.flux_progress.json`
- `loadFromFile()` - Read from `.flux_progress.json`

### Services (3 files)

#### `services/ai_service.dart` (774 lines)
**Purpose:** AI provider abstraction layer

**Key Features:**
- Dual provider support (Ollama localhost:11434, LM Studio localhost:1234)
- API endpoint resolution based on provider type
- Connection health checks with timeout
- Anti-hallucination 3-layer defense
- Model management (list, pull, delete)

**Provider Abstraction:**
```dart
enum AIProviderType { ollama, lmStudio }

// Ollama: POST http://localhost:11434/api/chat
// LM Studio: POST http://localhost:1234/v1/chat/completions
```

**Anti-Hallucination System:**
1. Model parameters (temperature=0.3, top_p=0.9)
2. Response cleaning (remove markdown, meta-commentary)
3. Garbage detection (repetition, excessive symbols)

**Public API:**
```dart
Future<(bool, String?, int)> checkConnection({...})
Future<String> translateText({...})
Future<String> detectGenre({...})
Future<String> generateGlossary({...})
Future<List<String>> getModelList()
```

#### `services/web_search_service.dart`
**Purpose:** RAG-enhanced glossary enrichment

**Key Features:**
- Web search for genre-specific terms
- Optional feature (requires internet)
- Enhances translation quality with contextual definitions

#### `services/dev_logger.dart`
**Purpose:** Centralized logging service

**Key Features:**
- Singleton pattern (shared instance)
- Log levels (info, warning, error)
- In-memory log storage for DevLogsScreen
- File output for debugging

### Screens (5 files)

#### `ui/screens/translate_screen.dart` (8,217 tokens, largest screen)
**Purpose:** Main translation interface

**Features:**
- File upload (drag-drop or file picker)
- Language selection (source/target)
- Translation progress bar
- Live chunk preview (source + translated)
- Pause/resume controls
- Resume detection (shows "Continue" button if progress exists)

**State:**
- `_selectedFile` - Current file path
- `_isTranslating` - Translation in progress flag
- `_progress` - Progress percentage (0.0-1.0)
- `_sourceChunk`, `_translatedChunk` - Live preview

#### `ui/screens/history_screen.dart`
**Purpose:** Translation history viewer

**Features:**
- Displays all completed translations from `history_log.json`
- Shows file name, source/target languages, completion time
- Click to view full translated text

#### `ui/screens/dictionary_screen.dart`
**Purpose:** Glossary management

**Features:**
- List all CSV glossaries in dictionary directory
- Upload new CSV files
- Edit existing glossaries
- Preview glossary entries

**CSV Format:**
```csv
source_term,target_term,context
```

#### `ui/screens/settings_screen.dart` (10,084 tokens, largest file by tokens)
**Purpose:** Application configuration

**Settings:**
- AI provider selection (Ollama/LM Studio)
- AI provider URL
- Model selection (dynamic list from provider)
- Theme mode (light/dark/system)
- UI language (Vietnamese/English)
- Dictionary directory path
- Internet permission (for web search)

#### `ui/screens/dev_logs_screen.dart`
**Purpose:** Debug console

**Features:**
- Real-time log display from DevLogger
- Filter by log level
- Export logs to file

### Widgets (9 files)

#### `ui/widgets/file_upload_zone.dart`
**Purpose:** Drag-drop file selector

**Features:**
- Drag-and-drop file upload
- File picker fallback (button click)
- Extension validation (`.txt`, `.epub`)
- Visual feedback (border color changes)

#### `ui/widgets/language_selector.dart`
**Purpose:** Language dropdown

**Languages Supported:**
- English (en)
- Vietnamese (vi)
- Chinese (zh)
- Japanese (ja)
- Korean (ko)

#### `ui/widgets/ollama_connection_dialog.dart`
**Purpose:** Connection error dialog

**Displays:**
- Error message
- Troubleshooting tips
- Retry button

#### `ui/widgets/ollama_health_check.dart`
**Purpose:** Background AI health monitor

**Features:**
- **Stealth mode:** No blocking dialogs
- Periodic connection checks (every 30 seconds)
- Sidebar badge indicator (red badge if disconnected)
- Non-intrusive user experience

#### `ui/widgets/path_setup_modal.dart`
**Purpose:** First-run project setup

**Displays:**
- Welcome message
- Dictionary directory selection
- Creates default glossary files if not exist

#### `ui/widgets/sidebar.dart` & `sidebar_item.dart`
**Purpose:** Navigation sidebar

**Features:**
- 5 navigation items (Translate, History, Dictionary, Settings, Logs)
- Active state highlighting
- Icon + label layout

#### `ui/widgets/title_bar.dart`
**Purpose:** Custom window title bar

**Features:**
- Height: 32px
- Drag-to-move window
- Custom minimize/maximize/close buttons
- Replaces native Windows title bar

#### `ui/widgets/upload_dictionary_modal.dart`
**Purpose:** CSV glossary upload modal

**Features:**
- File picker for CSV files
- Validation (CSV format check)
- Auto-save to dictionary directory

### Theme (2 files)

#### `ui/theme/app_theme.dart`
**Purpose:** Theme configuration and state management

**Light Theme:**
```dart
primaryColor: Color(0xFF2196F3)  // Blue
backgroundColor: Color(0xFFFFFFFF)  // White
```

**Dark Theme:**
```dart
primaryColor: Color(0xFFBB86FC)  // Purple
backgroundColor: Color(0xFF121212)  // Dark gray
```

**ThemeNotifier:**
- Extends ChangeNotifier
- Persists theme mode to SharedPreferences
- Notifies listeners on theme change

#### `ui/theme/config_provider.dart`
**Purpose:** Global configuration state

**Managed Config:**
- AI provider URL (default: `http://localhost:11434`)
- AI provider type (default: `ollama`)
- UI language (default: `vi`)
- Dictionary directory path
- Internet permission flag

**Persistence:** SharedPreferences

### Utils (3 files)

#### `utils/app_strings.dart`
**Purpose:** i18n string management

**Structure:**
```dart
static final Map<String, Map<String, String>> _strings = {
  'app_title': {'vi': 'FluxOrigin', 'en': 'FluxOrigin'},
  'translate_screen_title': {'vi': 'Dịch Tài Liệu', 'en': 'Translate'},
  // ~170 string entries
};
```

**API:**
```dart
AppStrings.get('key')  // Get string in current language
AppStrings.setLanguage('en')  // Switch language
```

#### `utils/file_parser.dart`
**Purpose:** File format parsing

**Supported Formats:**
- `.txt` - Plain text (UTF-8)
- `.epub` - Electronic publication (via `epubx` package)

**Processing:**
- Extracts text from EPUB XHTML chapters
- Normalizes whitespace and line breaks
- Returns concatenated full text

#### `utils/text_processor.dart` (205 lines)
**Purpose:** Text chunking and context extraction

**Key Methods:**

1. `smartSplit(text, targetSize=1000)` - Chunk text at sentence boundaries
   - Target: 1000 chars, Max: 1500 chars
   - Never splits mid-sentence
   - Looks backward first, then forward if needed

2. `extractLastSentences(text, maxLength=200)` - Get context from previous chunk
   - Extracts last 1-2 sentences (up to 200 chars)
   - Used for context passing between chunks

3. `createSample(text)` - Generate sample for genre detection
   - Takes head (4000 chars) + mid (3000 chars) + tail (3000 chars)
   - Used by AIService.detectGenre()

## Dependencies (pubspec.yaml)

### UI Framework
- **flutter** (SDK) - Cross-platform UI framework
- **google_fonts** ^6.1.0 - Google Fonts integration
- **font_awesome_flutter** ^10.6.0 - Font Awesome icons
- **flutter_animate** ^4.3.0 - Animation utilities

### Window Management
- **window_manager** ^0.3.0 - Custom window controls, title bar

### State Management
- **provider** ^6.1.0 - State management (ChangeNotifier pattern)
- **shared_preferences** ^2.5.3 - Key-value persistence

### File Handling
- **file_picker** ^10.3.7 - Native file picker dialog
- **desktop_drop** ^0.4.4 - Drag-drop support
- **csv** ^6.0.0 - CSV parsing for glossaries
- **epubx** ^4.0.0 - EPUB file parsing
- **html** ^0.15.4 - HTML parsing (for EPUB)
- **path** ^1.9.0 - Path manipulation utilities

### Network
- **http** ^1.1.0 - HTTP client for AI API calls
- **url_launcher** ^6.3.2 - Open URLs in browser

### Dev Dependencies
- **flutter_test** (SDK) - Testing framework
- **flutter_lints** ^3.0.0 - Dart linter rules
- **msix** ^3.16.0 - Windows MSIX package builder

### Dependency Overrides
- **image** ^3.3.0 - Image processing (override for compatibility)

## Test Files (test/)

### `ai_service_refactor_test.dart`
**Purpose:** Unit tests for AIService

**Coverage:**
- Connection checks (Ollama/LM Studio)
- API endpoint resolution
- Response cleaning (anti-hallucination)
- Garbage detection

### `text_processor_test.dart`
**Purpose:** Unit tests for TextProcessor

**Coverage:**
- Smart chunking algorithm
- Sentence boundary detection
- Context extraction
- Sample generation

### `verify_web_search.dart`
**Purpose:** Integration test for WebSearchService

**Coverage:**
- Web search API calls
- Glossary enrichment
- Error handling

### `widget_test.dart`
**Purpose:** Placeholder widget test (minimal implementation)

## Build Configuration

### Windows (windows/)
- **CMakeLists.txt** - CMake build configuration
- **runner/main.cpp** - Win32 entry point
- **runner/flutter_window.cpp** - Flutter view integration
- **runner/win32_window.cpp** - Window management (native)

### MSIX Packaging (pubspec.yaml)
```yaml
msix_config:
  display_name: FluxOrigin
  publisher_display_name: d-init-d
  identity_name: d-init-d.FluxOrigin
  msix_version: 2.0.2.0
  capabilities: "internetClient, internetClientServer"
```

## Generated/Binary Files (excluded from source control)

- `flutter_assets/` - Compiled Flutter assets
- `*.dll` - Plugin native libraries (window_manager, desktop_drop, etc.)
- `app.so` - Native code library
- `icudtl.dat` - ICU data file
- `flutter_windows.dll` - Flutter engine
- Build artifacts (not committed)

## Configuration Files

### `.gitignore`
- Standard Flutter/Dart ignore patterns
- Build directories (`build/`, `windows/flutter/ephemeral/`)
- IDE files (`.vscode/`, `.idea/`)

### `analysis_options.yaml`
- Dart linter rules (flutter_lints package)
- Custom lint rules (if any)

### `.metadata`
- Flutter metadata (version, revision)
- Auto-generated by Flutter CLI

## Documentation & Planning

### AGENTS.md
**Purpose:** Agent workflow documentation

**Content:**
- Subagent definitions (scout, docs-manager, etc.)
- Workflow guidelines
- Integration with Beads issue tracker

### PRIVACY.md
**Purpose:** Privacy policy

**Content:**
- No telemetry statement
- Local data processing assurance
- No cloud sync disclaimer

### LICENSE
**Purpose:** GPLv3 license text (7,526 tokens)

### README.md
**Purpose:** Project README (user-facing documentation)

**Content:**
- Installation instructions
- Usage guide
- Feature overview
- Screenshots/demo

### ui_design.html (10,693 tokens)
**Purpose:** UI design mockup/prototype

**Content:**
- HTML/CSS prototype of UI design
- Visual reference for UI implementation

## Code Metrics

### Top 5 Files by Token Count
1. `ui_design.html` - 10,693 tokens (UI mockup)
2. `lib/ui/screens/settings_screen.dart` - 10,084 tokens (comprehensive settings UI)
3. `lib/ui/screens/translate_screen.dart` - 8,217 tokens (main translation screen)
4. `LICENSE` - 7,526 tokens (GPLv3 full text)
5. `pubspec.lock` - 7,502 tokens (dependency lock file)

### Code Distribution
- **UI Layer:** ~60% (screens + widgets + theme)
- **Business Logic:** ~25% (controllers + services)
- **Utilities:** ~10% (utils + models)
- **Tests:** ~5%

## Key Architectural Patterns

### 1. Layered Architecture
```
UI → Controllers → Services → External APIs
     ↓
   Models ← Utils
```

### 2. State Management
- **Global State:** Provider (ThemeNotifier, ConfigProvider)
- **Local State:** StatefulWidget setState()
- **No Redux/BLoC** (lightweight Provider approach)

### 3. Service Abstraction
- AIService abstracts Ollama + LM Studio
- Provider type enum switches endpoints dynamically
- No tight coupling to specific AI backend

### 4. Progress Persistence
- JSON files for human-readable state
- Atomic writes to prevent corruption
- Resume from exact interruption point

### 5. Error Handling
- Try-catch in all async operations
- Tuple returns for status + data
- User-friendly error messages via AppStrings

## Critical Dependencies Graph

```
TranslateScreen
    ├── TranslationController
    │   ├── AIService
    │   │   └── http (AI API calls)
    │   ├── TextProcessor (chunking)
    │   ├── FileParser
    │   │   └── epubx (EPUB parsing)
    │   └── WebSearchService (optional)
    │       └── http (web search)
    ├── ThemeNotifier (Provider)
    └── ConfigProvider (Provider)
        └── shared_preferences (persistence)
```

## Security Considerations

### Input Validation
- File extension whitelist (`.txt`, `.epub`)
- Path sanitization for output files
- CSV format validation

### Data Privacy
- No telemetry/analytics
- No external API calls (except optional web search)
- All data stored locally

### Error Handling
- No sensitive data in error messages
- Graceful degradation on AI connection loss
- User-friendly error dialogs

## Performance Characteristics

### Translation Speed
- **Bottleneck:** AI inference (1-3 chunks/min, provider-dependent)
- **Chunk size:** 1000-1500 chars/chunk
- **Typical book:** 100-500 chunks (1-3 hours total)

### Memory Usage
- **App footprint:** <200MB (excluding LLM backend)
- **Peak memory:** O(file size + chunk array) during translation

### Disk I/O
- **Progress save:** ~1.5KB per chunk (incremental)
- **History log:** Append-only JSON array

## Future Enhancement Opportunities

### Code Improvements
1. **Parallel chunk translation** (with dependency management)
2. **Streaming file parser** (for files >10MB)
3. **Undo/redo for manual edits** (live preview editing)
4. **Export formats** (PDF, DOCX, MOBI)

### Architecture Refactoring
1. **Dependency Injection** (instead of direct instantiation)
2. **Repository pattern** (for progress/history persistence)
3. **Event bus** (for cross-component communication)
4. **Plugin system** (for custom post-processing)

### Testing Coverage
1. **Widget tests** (current coverage minimal)
2. **Integration tests** (E2E translation flow)
3. **Performance tests** (chunking benchmarks)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-04
**Codebase Status:** Production (v2.0.2)
**Total Files Analyzed:** 74 files (120,730 tokens, 556,231 chars)
