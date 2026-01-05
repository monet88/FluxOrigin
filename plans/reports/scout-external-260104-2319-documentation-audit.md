# Documentation Audit Report - FluxOrigin
Generated: 2026-01-04 23:19
Subagent: scout-external (a412c0b)
CWD: F:\CodeBase\FluxOrigin

## Executive Summary
FluxOrigin is a Flutter-based Windows desktop application for AI-powered book/document translation using local LLM providers (Ollama/LM Studio). Current documentation is comprehensive at user level but lacks developer/architecture documentation.

## Project Identity
- Name: FluxOrigin - AI Book Translator
- Version: 2.0.2
- Platform: Windows 10/11 (64-bit)
- Framework: Flutter 3.x
- License: GPLv3 with trademark restrictions
- Developer: d-init-d (MINH DUNG NGUYEN)
- Contact: d.init.d.contact@gmail.com

## Documentation Inventory

### Existing Documentation (Root Level)

1. README.md (170 lines) - Comprehensive user documentation in Vietnamese
   - Features, installation, usage guide, model recommendations, project structure

2. AGENTS.md (41 lines) - Developer workflow instructions
   - bd (beads) issue tracking workflow
   - Mandatory "landing the plane" completion protocol

3. PRIVACY.md (40 lines) - Complete privacy policy
   - Last updated: Dec 04, 2025
   - Emphasizes local-first architecture, no cloud data collection

4. LICENSE (680 lines) - Full GPLv3 license text
   - Custom trademark clause protecting "FluxOrigin" name/logo

5. docs/ directory - Does NOT exist

## Project Overview

### Description
Desktop app for automatic book/document translation using local AI. Successor to "n8n book translator" - eliminates n8n workflow dependency for all-in-one experience.

### Key Features
- Native Flutter App: Single .exe, no Docker/Node.js/n8n setup
- Multi-AI Provider: Supports Ollama + LM Studio
- Dictionary Management: Upload custom terminology/proper nouns
- Smart Text Processing: Auto-chunking to avoid token limits
- Live Translation Preview: Real-time translation display
- Dev Logs: Developer debug view for requests/responses
- Translation History: Auto-saves previous translations
- Web Search (Experimental): Context enhancement via search

### Supported File Formats
- .txt (plain text)
- .md (Markdown)
- .epub (eBook)

## System Requirements
- OS: Windows 10/11 (64-bit)
- AI Backend: Ollama or LM Studio
- RAM: 8GB+ recommended

## Architecture

### Project Structure
lib/
├── ui/                    # User interface
│   ├── screens/           # Main screens
│   ├── widgets/           # Reusable widgets
│   └── theme/             # Theme & Config Provider
├── services/              # API logic
│   ├── ai_service.dart
│   ├── web_search_service.dart
│   └── dev_logger.dart
├── controllers/           # State management
├── utils/                 # Text/file processing tools
└── models/                # Data definitions

### Technology Stack
- Flutter SDK 3.x
- Dart >=3.0.0 <4.0.0
- UI: google_fonts, font_awesome_flutter, flutter_animate
- State: provider
- Files: file_picker, desktop_drop, epubx
- Network: http, url_launcher
- Storage: shared_preferences
- Deploy: msix (Windows Store)

## AI Model Recommendations

### By Hardware Tier
- 4-6GB: Qwen2.5-3B, Gemma3-4B (Balanced)
- 8GB: Qwen2.5-7B, Llama3.1-8B (Good)
- 12GB: Qwen3-8B, Gemma3-12B (Excellent)
- 16GB: Qwen3-14B, Qwen2.5-14B (Excellent)
- 24GB+: Gemma3-27B, Qwen3-30B-A3B (Excellent)
- 42GB+: Llama3.3-70B (Workstation)

### By Use Case
- Chinese to Vietnamese novels: Qwen3-8B, Qwen3-14B
- English to Vietnamese technical: Llama3.1-8B, Gemma3-12B
- Low-end hardware: Qwen2.5-3B, Gemma3-4B
- Highest quality: Qwen3-14B, Gemma3-27B

## Privacy & Data Handling

### Core Privacy Principles
1. Local-First Architecture
   - No personal data collection
   - No cloud uploads of user files/content
   - All processing happens locally

2. AI Processing
   - Connects to LOCAL AI models (Ollama/LM Studio)
   - Translation text stays within local environment
   - No external API calls for generation

3. Internet Usage (Limited)
   - Only for: Microsoft Store license verification, app updates
   - NOT used for content transmission

4. Analytics
   - No third-party analytics SDKs
   - Local dev logs only

## Licensing Details
- License Type: GPLv3
- Trademark Protection: "FluxOrigin" name + logo are proprietary
- Fork/Modification Rules:
  * Can fork and modify code under GPLv3
  * MUST change name and logo for public distribution of modified versions

## Developer Workflow

### Issue Tracking System (bd/beads)
- bd onboard
- bd ready
- bd show <id>
- bd update <id> --status in_progress
- bd close <id>
- bd sync

### Session Completion Protocol
MANDATORY WORKFLOW:
1. File issues for remaining work
2. Run quality gates
3. Update issue status
4. PUSH TO REMOTE (critical)
5. Clean up
6. Verify
7. Hand off

Critical Rules:
- Work NOT complete until git push succeeds
- NEVER stop before pushing
- NEVER delegate push to user

## Documentation Gaps

### Missing Documentation
1. Architecture Documentation
   - No detailed architecture diagrams
   - No data flow documentation
   - No state management patterns explained
   - No API documentation

2. Developer Documentation
   - No contribution guidelines
   - No code style guide
   - No testing documentation
   - No build/deployment documentation

3. API/Service Documentation
   - No ai_service.dart documentation
   - No web_search_service.dart documentation
   - No dev_logger.dart documentation

4. User Documentation Gaps
   - No troubleshooting guide
   - No FAQ
   - No screenshots/visual guide
   - No video tutorials

5. Technical Documentation
   - No chunking algorithm explanation
   - No dictionary format specification
   - No custom model integration guide
   - No performance tuning guide

### Missing Files/Directories
- docs/ directory (absent)
- CONTRIBUTING.md
- CHANGELOG.md
- CODE_OF_CONDUCT.md
- API reference documentation

## Documentation Quality Assessment

### Strengths
- README is comprehensive and well-structured
- Vietnamese localization for target audience
- Clear installation instructions
- Excellent AI model recommendation table
- Privacy policy is clear and specific
- AGENTS.md provides clear developer workflow

### Weaknesses
- No developer/architecture documentation
- No API documentation
- No visual aids (screenshots, diagrams)
- No troubleshooting guide
- No changelog
- Missing contribution guidelines

## Recommendations

### High Priority
1. Create docs/ directory with:
   - architecture.md
   - api-reference.md
   - troubleshooting.md
   - changelog.md
2. Add screenshots to README
3. Create CONTRIBUTING.md

### Medium Priority
4. Document chunking algorithm
5. Create dictionary file format specification
6. Add performance tuning guide
7. Create developer onboarding guide

### Low Priority
8. Create video tutorial
9. Add FAQ section
10. Create code style guide

## Unresolved Questions
1. Where is the actual installer (FluxOrigin_Installer_v1.0.1.exe)?
2. Is there a separate documentation repository?
3. Are there any internal architecture diagrams not committed?
4. What is the target audience distribution (developer vs end-user)?
5. Is Vietnamese the only target language for docs?
