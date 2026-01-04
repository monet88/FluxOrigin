# FluxOrigin - Product Development Requirements (PDR)

## Project Overview

**FluxOrigin** is an AI-powered desktop translation application specifically designed for translating books and long-form content using local LLM providers. Built for Windows 10/11, it offers a privacy-focused, offline-capable solution for high-quality literary translation.

**Version:** 2.0.2
**License:** GPLv3
**Platform:** Windows 10/11 (64-bit)
**Technology:** Flutter 3.x, Dart 3.x

## Vision & Goals

### Primary Vision
Democratize book translation by leveraging local AI models, enabling translators and readers to:
- Translate entire books with context-aware AI assistance
- Maintain translation privacy (no cloud dependencies)
- Resume interrupted translation sessions seamlessly
- Customize translation with genre-specific glossaries

### Key Objectives
1. **Quality**: Context-aware translation with anti-hallucination safeguards
2. **Reliability**: Resume-capable pipeline with automatic progress saving
3. **Privacy**: 100% local processing, no external data transmission
4. **Usability**: Intuitive UI for non-technical users
5. **Flexibility**: Support multiple AI providers (Ollama, LM Studio)

## Target Users

### Primary Personas
1. **Amateur Translators**: Individuals translating favorite novels for personal use or small communities
2. **Language Enthusiasts**: Readers who want to access content not available in their language
3. **Translation Professionals**: Translators seeking AI assistance for first-draft generation

### User Requirements
- **Technical Skill**: Basic computer literacy (file management, software installation)
- **Hardware**: Windows 10/11 PC with minimum 8GB RAM (16GB+ recommended for local LLM)
- **AI Backend**: Pre-installed Ollama or LM Studio with downloaded models

## Core Features

### 1. Smart Translation Pipeline
**Priority:** P0 (Critical)

- **Context-Aware Chunking**: Splits text at sentence boundaries (1000-1500 chars/chunk)
- **Previous Context Passing**: Includes last 200 chars from previous chunk for continuity
- **Resume Capability**: Saves progress after each chunk to `.flux_progress.json`
- **Multi-Format Support**: TXT and EPUB file parsing

**Acceptance Criteria:**
- Translation resumes from exact interruption point
- Chunk boundaries never split sentences
- Context maintains narrative flow across chunks

### 2. Genre-Specific Glossaries
**Priority:** P0 (Critical)

- **Auto-Detection**: Identifies genre (Martial Arts, Romance, Business, Other)
- **CSV Glossaries**: Loads custom term mappings from CSV files
- **RAG Enrichment**: Optional web search to enhance glossary terms (requires internet)
- **Multi-Language**: Supports Vietnamese ↔ English translation pairs

**Acceptance Criteria:**
- Genre detection accuracy >80% on sample text
- Glossary terms applied consistently across translation
- CSV format: `source_term,target_term,context`

### 3. AI Provider Flexibility
**Priority:** P0 (Critical)

- **Ollama Integration**: Default provider (localhost:11434)
- **LM Studio Integration**: Alternative provider (localhost:1234)
- **Health Monitoring**: Background connection checks (stealth mode)
- **Model Selection**: Dynamic model list from active provider

**Acceptance Criteria:**
- Seamless switching between providers without restart
- Connection errors display non-blocking notifications
- Model list refreshes on provider change

### 4. Translation Progress Management
**Priority:** P1 (High)

- **Live Preview**: Real-time display of source/translated chunks
- **Progress Tracking**: Visual progress bar with percentage
- **History Log**: All completed translations saved to `history_log.json`
- **Pause/Resume**: User can pause mid-translation, resume later

**Acceptance Criteria:**
- Progress updates every chunk (not batch)
- History log persists across app sessions
- Pause responds within 2 seconds (after current chunk)

### 5. Anti-Hallucination System
**Priority:** P0 (Critical)

**3-Layer Defense:**
1. **Model Parameters**: `temperature=0.3`, `top_p=0.9`, `repeat_penalty=1.1`
2. **Response Cleaning**: Removes markdown artifacts, code blocks, meta-commentary
3. **Garbage Detection**: Rejects responses with excessive repetition or non-text content

**Acceptance Criteria:**
- Hallucination rate <5% on test corpus (1000+ chunks)
- Invalid responses automatically retried (max 3 attempts)
- Clean output free of formatting artifacts

## Technical Requirements

### Functional Requirements
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | Support TXT and EPUB file formats | P0 | ✅ Implemented |
| FR-02 | Context-aware chunking with sentence boundaries | P0 | ✅ Implemented |
| FR-03 | Resume translation from interruption point | P0 | ✅ Implemented |
| FR-04 | Genre detection (4 categories) | P0 | ✅ Implemented |
| FR-05 | CSV glossary management | P0 | ✅ Implemented |
| FR-06 | Ollama and LM Studio provider support | P0 | ✅ Implemented |
| FR-07 | Translation history logging | P1 | ✅ Implemented |
| FR-08 | Light/Dark theme support | P2 | ✅ Implemented |
| FR-09 | Vietnamese and English UI localization | P1 | ✅ Implemented |
| FR-10 | Developer logs console | P2 | ✅ Implemented |

### Non-Functional Requirements
| ID | Requirement | Target | Measurement |
|----|-------------|--------|-------------|
| NFR-01 | Translation speed | 1-3 chunks/min | Depends on local LLM performance |
| NFR-02 | App startup time | <3 seconds | From launch to main screen |
| NFR-03 | Memory footprint | <200MB | Excluding LLM backend |
| NFR-04 | Progress save frequency | Every chunk | Max 1.5KB/chunk overhead |
| NFR-05 | UI responsiveness | <100ms | For user interactions |
| NFR-06 | Crash recovery | 100% | No data loss on unexpected exit |

### Technical Constraints
- **Platform**: Windows-only (Flutter desktop, no web/mobile)
- **AI Dependency**: Requires external Ollama/LM Studio installation
- **Internet**: Optional (only for RAG glossary enrichment)
- **Storage**: ~50MB app + variable for translation data

## Success Metrics

### Primary KPIs
1. **Translation Completion Rate**: >90% of started translations finished
2. **Resume Success Rate**: 100% of interrupted sessions resume correctly
3. **User Retention**: >70% of users translate second book within 30 days
4. **Context Quality**: >85% user satisfaction on chunk continuity (survey)

### Secondary KPIs
1. **Average Translation Speed**: 2000+ words/hour (user + AI combined)
2. **Glossary Usage**: >50% of users create custom glossaries
3. **Error Rate**: <1% fatal errors per 1000 chunks
4. **Support Tickets**: <5% of users contact support

## Development Phases

### Phase 1: Core Translation Engine ✅ (Completed)
- Text parsing (TXT/EPUB)
- Smart chunking algorithm
- AI service abstraction (Ollama/LM Studio)
- Basic UI with file upload

### Phase 2: Resume & Reliability ✅ (Completed)
- Progress persistence (`.flux_progress.json`)
- Resume functionality
- Error handling and retry logic
- Translation history

### Phase 3: Quality Enhancements ✅ (Completed)
- Genre detection
- Glossary system (CSV)
- RAG enrichment (web search)
- Anti-hallucination 3-layer system

### Phase 4: UX Polish ✅ (Completed - v2.0.x)
- Live translation preview
- Stealth mode health checks
- Theme system (light/dark)
- i18n (Vietnamese/English)

### Phase 5: Future Enhancements (Planned)
- PDF support
- Batch translation (multiple files)
- Translation quality metrics
- Export formats (DOCX, PDF)
- Plugin system for custom post-processing

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| LLM provider incompatibility | Medium | High | Abstract API layer, provider type enum |
| Translation quality degradation | Medium | High | 3-layer anti-hallucination, user glossaries |
| Large file memory issues | Low | Medium | Streaming parser, chunk-by-chunk processing |
| Progress file corruption | Low | High | Atomic writes, backup before overwrite |
| Windows version fragmentation | Low | Low | Target Windows 10+ (95% market coverage) |

## Dependencies

### External Services
- **Ollama** (optional): Default AI provider
- **LM Studio** (optional): Alternative AI provider
- **Web Search** (optional): RAG glossary enrichment

### Technology Stack
- **Flutter 3.x**: UI framework
- **Provider**: State management
- **window_manager**: Custom title bar, window controls
- **epubx**: EPUB parsing
- **csv**: Glossary format

## Compliance & Licensing

- **License**: GPLv3 (open-source)
- **Data Privacy**: No telemetry, no cloud sync
- **Content Rights**: User responsible for translation copyright compliance
- **AI Model Usage**: User responsible for LLM license compliance (e.g., LLaMA 2/3 terms)

## Maintenance & Support

### Update Strategy
- **Patch Releases** (x.x.Z): Bug fixes, performance improvements
- **Minor Releases** (x.Y.0): New features, UI enhancements
- **Major Releases** (X.0.0): Breaking changes, architecture overhaul

### Support Channels
- GitHub Issues (primary)
- Community Discord (planned)
- Documentation wiki (planned)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-04
**Status:** Active Development (v2.0.2)
