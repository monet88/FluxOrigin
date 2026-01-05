FluxOrigin lib/ Directory - Complete File Structure Report
Project: FluxOrigin (Flutter Translation Application)
Scope: Complete lib/ directory exploration
Date: 2026-01-04
Total Files: 25 Dart files

EXECUTIVE SUMMARY
FluxOrigin: Desktop Flutter app for AI-powered document translation (Chinese wuxia/romance to Vietnamese). Uses Provider for state management, supports Ollama and LM Studio AI backends.

Core Architecture:
- State Management: Provider (ChangeNotifier)
- AI Integration: HTTP-based (Ollama/LM Studio APIs)
- File Support: TXT, EPUB
- Translation: Genre detection, chunked processing, progress persistence, web search enrichment

DIRECTORY STRUCTURE
lib/
- main.dart - Application entry point
- controllers/translation_controller.dart - Translation orchestration (564 lines)
- models/translation_progress.dart - Progress persistence model
- services/ai_service.dart - AI provider abstraction (774 lines)
- services/dev_logger.dart - Development logging
- services/web_search_service.dart - RAG web search
- ui/app.dart - Root MaterialApp widget
- ui/screens/ - 5 screens (Translate, History, Dictionary, Settings, DevLogs)
- ui/theme/ - ThemeNotifier, ConfigProvider
- ui/widgets/ - 9 widgets (Sidebar, TitleBar, FileUpload, Modals, HealthCheck)
- utils/ - app_strings (i18n), file_parser, text_processor

ENTRY POINTS
main.dart: Bootstrap, window config (1000x700), MultiProvider setup
ui/app.dart: MaterialApp with IndexedStack navigation (5 screens), ThemeNotifier, ConfigProvider

STATE MANAGEMENT
ui/theme/config_provider.dart - Global config store (SharedPreferences)
- State: projectPath, selectedModel, ollamaUrl, lmStudioUrl, aiProvider, appLanguage, ollamaConnected
- Methods: loadConfig(), setProjectPath(), checkOllamaHealth()

ui/theme/app_theme.dart - Theme toggle
- Light: #FDFCF8 paper, #043222 primary
- Dark: #111111 paper, #000000 sidebar

TRANSLATION WORKFLOW
controllers/translation_controller.dart (564 lines)
Pipeline: Upload → Parse → Chunk → Detect Genre → Generate Glossary → Enrich (RAG) → Translate → Save → Merge

Key Methods:
1. processFile() - Main orchestrator with resume logic
2. Initialization - Extract text, split chunks, detect genre, generate glossary, enrich
3. Translation Loop - Context-aware, save after every chunk, pause handling
4. Finalization - Merge chunks, delete progress, add to history

SERVICES
services/ai_service.dart (774 lines)
- Ollama: /api/chat, /api/tags, /api/pull, /api/delete
- LM Studio: /v1/chat/completions, /v1/models
- Key: checkConnection(), detectGenre(), generateGlossary(), translateChunk()
- Anti-Hallucination: 3-layer system (model params, cleanResponse, isGarbageOutput)

services/web_search_service.dart - RAG glossary enrichment
services/dev_logger.dart - Centralized logging (info, debug, warning, error, request, response)

MODELS
models/translation_progress.dart - Resume state persistence
- Fields: sourcePath, glossary, systemPrompt, genre, rawChunks, translatedChunks, currentIndex
- Methods: toJson(), fromJson(), loadFromFile(), saveToFile()
- Location: {dictionaryDir}/{fileName}.flux_progress.json

UTILITIES
utils/app_strings.dart - i18n strings (Vietnamese + English), ~170 strings
utils/file_parser.dart - Extract text from .txt/.epub
utils/text_processor.dart - smartSplit(), createSample(), extractLastSentences()

WIDGETS (9 total)
- file_upload_zone.dart - Drag-drop upload
- ollama_health_check.dart - Non-blocking AI health monitor
- sidebar.dart - 5-item navigation (badge if AI disconnected)
- title_bar.dart - Custom window controls (32px)
- path_setup_modal.dart - First-run project setup
- language_selector.dart, ollama_connection_dialog.dart, sidebar_item.dart, upload_dictionary_modal.dart

API/BACKEND INTEGRATIONS
Ollama (Default): http://localhost:11434
LM Studio (Alternative): http://localhost:1234 (OpenAI-compatible)
Web Search: RAG glossary enrichment (implementation not visible)

CONFIGURATION
SharedPreferences: project_path, selected_model, ollama_url, lm_studio_url, ai_provider, app_language
File-Based: history_log.json, {fileName}.flux_progress.json, {fileName}_glossary.csv

SUMMARY TABLE
Entry Points: 2 (main.dart, app.dart)
Controllers: 1 (translation_controller.dart - 564 lines)
Models: 1 (translation_progress.dart)
Services: 3 (AI abstraction, RAG search, logging)
Screens: 5 (Translate, History, Dictionary, Settings, DevLogs)
Widgets: 9 (Sidebar, TitleBar, FileUpload, Modals, HealthCheck)
Theme: 2 (ThemeNotifier, ConfigProvider)
Utils: 3 (i18n, file parsing, text processing)

Total: 25 Dart files, ~3500+ lines of code

State Management: Provider (ChangeNotifier)
Dependencies: provider, window_manager, google_fonts, shared_preferences, http, csv, path, epub_view

UNRESOLVED QUESTIONS
1. web_search_service.dart implementation - which API?
2. file_parser.dart - exact EPUB parsing library?
3. text_processor.dart - sentence boundary detection logic?
4. Error recovery - network timeout handling UX?
5. Model naming - LM Studio vs Ollama name conversion?
