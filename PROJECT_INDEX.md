# Project Index: FluxOrigin

**Generated**: 2026-01-05
**Version**: 2.0.2
**Type**: Flutter Windows Desktop Application

---

## 📁 Project Structure

```
FluxOrigin/
├── lib/                        # Dart source code (25 files)
│   ├── main.dart               # Entry point
│   ├── controllers/            # State orchestration
│   ├── models/                 # Data models
│   ├── services/               # Business logic & API
│   ├── ui/                     # User interface
│   │   ├── app.dart            # Root MaterialApp
│   │   ├── screens/            # 5 screens
│   │   ├── theme/              # Theme & config providers
│   │   └── widgets/            # Reusable components (9)
│   └── utils/                  # Helpers & utilities
├── test/                       # Tests (4 files)
├── docs/                       # Documentation (4 files)
├── assets/                     # Logo images
├── windows/                    # Windows native code
└── .beads/                     # Issue tracking
```

---

## 🚀 Entry Points

| Path | Purpose |
|------|---------|
| `lib/main.dart` | App entry, window manager setup, Provider init |
| `lib/ui/app.dart` | Root MaterialApp, IndexedStack navigation |
| `test/widget_test.dart` | Test entry (placeholder) |

---

## 📦 Core Modules

### Controllers
| File | Purpose |
|------|---------|
| `translation_controller.dart` | Resume-capable translation pipeline, context-aware chunking |

### Models
| File | Purpose |
|------|---------|
| `translation_progress.dart` | JSON-serializable progress state |

### Services
| File | Purpose |
|------|---------|
| `ai_service.dart` | Ollama/LM Studio abstraction, 3-layer anti-hallucination |
| `web_search_service.dart` | RAG-enhanced glossary enrichment |
| `dev_logger.dart` | Centralized logging (info, debug, error) |

### Screens
| File | Purpose |
|------|---------|
| `translate_screen.dart` | Main UI: file upload, progress, live preview |
| `history_screen.dart` | Translation history from history_log.json |
| `dictionary_screen.dart` | Glossary management (.csv files) |
| `settings_screen.dart` | AI provider config, theme, language |
| `dev_logs_screen.dart` | Debug console viewer |

### Theme
| File | Purpose |
|------|---------|
| `app_theme.dart` | Light/Dark theme definitions, ThemeNotifier |
| `config_provider.dart` | Global config: AI URLs, project path, model, language |

### Utils
| File | Purpose |
|------|---------|
| `app_strings.dart` | i18n strings (~170, Vietnamese + English) |
| `file_parser.dart` | TXT/EPUB text extraction |
| `text_processor.dart` | Smart chunking, context extraction |

### Widgets (9 files)
- `file_upload_zone.dart` - Drag-drop with .txt/.epub validation
- `language_selector.dart` - Source/target language dropdown
- `ollama_connection_dialog.dart` - Connection error dialog
- `ollama_health_check.dart` - Background AI health monitor (stealth)
- `path_setup_modal.dart` - First-run project setup
- `sidebar.dart`, `sidebar_item.dart` - Navigation
- `title_bar.dart` - Custom 32px window title bar
- `upload_dictionary_modal.dart` - CSV glossary upload

---

## 🔧 Configuration

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Flutter dependencies, MSIX config |
| `analysis_options.yaml` | Dart linter rules |
| `.beads/config.yaml` | Issue tracking config |

---

## 📚 Documentation

| File | Topic |
|------|-------|
| `docs/project-overview-pdr.md` | Vision, requirements, roadmap |
| `docs/system-architecture.md` | Architecture diagrams, data flow |
| `docs/codebase-summary.md` | Directory structure, module breakdown |
| `docs/code-standards.md` | Coding conventions, review checklist |
| `README.md` | User guide (Vietnamese) |
| `PRIVACY.md` | Privacy policy |
| `AGENTS.md` | Developer workflow with beads |

---

## 🧪 Test Coverage

| File | Coverage |
|------|----------|
| `ai_service_refactor_test.dart` | AIService unit tests |
| `text_processor_test.dart` | Text processing tests |
| `verify_web_search.dart` | Web search verification |
| `widget_test.dart` | Placeholder |

**Status**: Core services ✅, UI ❌

---

## 🔗 Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.0 | State management |
| `window_manager` | ^0.3.0 | Custom window controls |
| `google_fonts` | ^6.1.0 | Typography |
| `http` | ^1.1.0 | API calls to AI backends |
| `epubx` | ^4.0.0 | EPUB parsing |
| `csv` | ^6.0.0 | Dictionary CSV handling |
| `desktop_drop` | ^0.4.4 | Drag-drop file upload |
| `shared_preferences` | ^2.5.3 | Local settings persistence |
| `msix` | ^3.16.0 | Windows Store packaging |

---

## 📝 Quick Start

```bash
# 1. Clone & setup
git clone https://github.com/d-init-d/FluxOrigin.git
cd FluxOrigin
flutter pub get

# 2. Run
flutter run -d windows

# 3. Test
flutter test

# 4. Build MSIX
flutter pub run msix:create
```

---

## 🎯 Key Architecture Points

1. **State**: Provider (ThemeNotifier, ConfigProvider)
2. **AI Backends**: Ollama (11434), LM Studio (1234)
3. **Translation Pipeline**: Upload → Parse → Chunk → Detect Genre → Glossary → Translate → Merge
4. **Persistence**: .flux_progress.json (resume-capable)
5. **Anti-hallucination**: 3-layer (params, cleaning, garbage detection)

---

## 📊 Code Metrics

| Metric | Value |
|--------|-------|
| Dart files | 25 |
| Test files | 4 |
| Doc files | 7 |
| Total LoC | ~3,500 |
| Largest file | `ai_service.dart` (774 lines) |

---

*Index size: ~3KB | Full codebase read: ~58K tokens | Savings: 94%*
