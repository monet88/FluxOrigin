# FluxOrigin Project Structure Report

**Generated**: 2026-01-04 23:19  
**Scope**: assets/, pubspec.yaml, .github/, windows/, .kiro/, test/

---

## 1. Assets Directory (`assets/`)

### Images
- `F:\CodeBase\FluxOrigin\assets\fluxorigin_logo.png` (61KB)
- `F:\CodeBase\FluxOrigin\assets\fluxorigin logo.png` (61KB)

**Note**: Identical files (61,013 bytes each), likely duplicates with different naming conventions.

### Fonts
Không có font files trong thư mục assets/.

### i18n (Internationalization)
Không có i18n files trong thư mục assets/.

---

## 2. Dependencies (`pubspec.yaml`)

### Project Info
- **Name**: flux_origin
- **Version**: 2.0.2+1
- **Description**: Translation desktop application for Windows
- **Dart SDK**: >=3.0.0 <4.0.0

### Production Dependencies

#### Window Management
- `window_manager: ^0.3.0` - Quản lý cửa sổ native (resize, minimize, maximize, position)

#### UI & Visual
- `google_fonts: ^6.1.0` - Fonts từ Google Fonts API
- `font_awesome_flutter: ^10.6.0` - Icon library Font Awesome
- `flutter_animate: ^4.3.0` - Animation effects và transitions

#### State Management & Storage
- `provider: ^6.1.0` - State management solution
- `shared_preferences: ^2.5.3` - Key-value persistent storage

#### File Operations
- `file_picker: ^10.3.7` - File/folder selection dialogs
- `desktop_drop: ^0.4.4` - Drag-and-drop file handling
- `path: ^1.9.0` - Cross-platform path manipulation

#### Networking & Web
- `http: ^1.1.0` - HTTP client cho API calls
- `url_launcher: ^6.3.2` - Mở URLs trong browser/external apps

#### Data Processing
- `csv: ^6.0.0` - CSV file parsing/generation
- `html: ^0.15.4` - HTML document parsing/manipulation
- `epubx: ^4.0.0` - EPUB file format parser (e-books)

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^3.0.0` - Linting rules cho code quality
- `msix: ^3.16.0` - MSIX package builder cho Windows Store

### Dependency Overrides
- `image: ^3.3.0` - Overridden để fix compatibility issues

---

## 3. CI/CD Workflows (`.github/`)

**Status**: Không có CI/CD workflows được cấu hình.

Directory `.github/workflows/` không tồn tại trong project.

**Recommendation**: Consider thêm GitHub Actions cho:
- Automated testing
- Build automation
- Release packaging
- Code quality checks

---

## 4. Windows Configuration (`windows/`)

### Build Configuration
- `CMakeLists.txt` - Main CMake project config
- `flutter/CMakeLists.txt` - Auto-generated Flutter CMake config
- `runner/CMakeLists.txt` - Application runner config

### Application Entry & Core
- `runner/main.cpp` - Windows entry point, COM init, message loop
- `runner/flutter_window.cpp/.h` - Flutter view hosting trong Windows native window
- `runner/win32_window.cpp/.h` - Base Win32 window abstraction (DPI-aware)

### Utilities & Resources
- `runner/utils.cpp/.h` - Console attach, command-line parsing, UTF-8/UTF-16 conversion
- `runner/Runner.rc` - Windows resource script (icons, version info)
- `runner/resource.h` - Resource ID definitions
- `runner/runner.exe.manifest` - App manifest (DPI awareness, Windows 10/11 compatibility)

### Plugin System
- `flutter/generated_plugin_registrant.cc/.h` - Auto-generated plugin registration
- `flutter/generated_plugins.cmake` - Auto-generated CMake plugin config

### Ignore Rules
- `.gitignore` - Build artifacts, VS user files, Flutter temp files

---

## 5. Project Configuration (`.kiro/`)

### MCP Configuration
**File**: `.kiro/settings/mcp.json`

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "env": {},
      "disabled": true,
      "autoApprove": []
    }
  }
}
```

**Purpose**: Multi-Client Protocol server configuration (currently disabled)

---

## 6. Test Structure (`test/`)

### Test Files
1. **`widget_test.dart`** - UI widget test placeholder (minimal coverage)
2. **`verify_web_search.dart`** - `WebSearchService` functional verification script
   - Tests: EN, VI, ZH language lookups
   - Format: Simple Dart script với `print` assertions
3. **`text_processor_test.dart`** - `TextProcessor.smartSplit` comprehensive tests
   - Tests: Various text splitting scenarios
   - Format: Dart script với `print` verification
4. **`ai_service_refactor_test.dart`** - **Well-structured** `AIService.cleanResponse` unit tests
   - Uses: `flutter_test` framework với `group` và `test`
   - Coverage: Response cleaning logic

### Test Organization
- **Structured**: Only `ai_service_refactor_test.dart` uses proper `flutter_test` framework
- **Ad-hoc**: `verify_web_search.dart` và `text_processor_test.dart` are verification scripts
- **UI Testing**: Minimal (only placeholder exists)

### Coverage Areas
- ✅ AIService response cleaning
- ✅ Text processing/splitting
- ✅ Web search functionality
- ❌ UI widgets (placeholder only)
- ❌ Integration tests
- ❌ E2E tests

**Recommendation**: Expand test coverage với:
- Widget tests cho UI components
- Integration tests cho feature flows
- Migrate verification scripts sang `flutter_test` format

---

## 7. MSIX Configuration (`pubspec.yaml`)

### Windows Store Package Settings
```yaml
display_name: FluxOrigin
publisher_display_name: d-init-d
identity_name: d-init-d.FluxOrigin
publisher: CN=94D446F9-8A96-471F-9749-DFF18CBA6CD8
msix_version: 2.0.2.0
logo_path: D:\FluxOrigin\assets\fluxorigin logo.png
store: true
capabilities: "internetClient, internetClientServer"
```

**Note**: Logo path `D:\FluxOrigin\assets\fluxorigin logo.png` là absolute path, có thể gây issues trên máy khác.

---

## Key File Paths Summary

### Assets
- `F:\CodeBase\FluxOrigin\assets\fluxorigin_logo.png`
- `F:\CodeBase\FluxOrigin\assets\fluxorigin logo.png`

### Configuration
- `F:\CodeBase\FluxOrigin\pubspec.yaml`
- `F:\CodeBase\FluxOrigin\.kiro\settings\mcp.json`

### Windows Native
- `F:\CodeBase\FluxOrigin\windows\CMakeLists.txt`
- `F:\CodeBase\FluxOrigin\windows\runner\main.cpp`
- `F:\CodeBase\FluxOrigin\windows\runner\flutter_window.cpp`
- `F:\CodeBase\FluxOrigin\windows\runner\win32_window.cpp`
- `F:\CodeBase\FluxOrigin\windows\runner\Runner.rc`
- `F:\CodeBase\FluxOrigin\windows\runner\runner.exe.manifest`

### Tests
- `F:\CodeBase\FluxOrigin\test\ai_service_refactor_test.dart`
- `F:\CodeBase\FluxOrigin\test\text_processor_test.dart`
- `F:\CodeBase\FluxOrigin\test\verify_web_search.dart`
- `F:\CodeBase\FluxOrigin\test\widget_test.dart`

---

## Unresolved Questions

1. **Asset duplication**: Tại sao có 2 logo files giống hệt nhau với tên khác nhau?
2. **MSIX logo path**: Hardcoded path `D:\FluxOrigin\` có thể gây build failures trên môi trường khác - cần chuyển sang relative path?
3. **MCP server**: Mục đích của `mcp-server-fetch` config (hiện đang disabled)?
4. **CI/CD absence**: Có kế hoạch thêm automated workflows không?
5. **Test coverage**: UI tests chỉ có placeholder - kế hoạch mở rộng testing?

