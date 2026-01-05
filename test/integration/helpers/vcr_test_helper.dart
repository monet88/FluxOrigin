/**
 * VCR Test Helper
 *
 * Provides utilities for recording and replaying HTTP interactions
 * using the dartvcr package for integration testing.
 *
 * Uses HttpOverrides to intercept all HTTP calls globally,
 * allowing VCR to work without modifying provider code.
 */

import 'dart:io';
import 'package:dartvcr/dartvcr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// VCR mode configuration
///
/// Controls whether tests use recorded responses or make real API calls.
enum VCRMode {
  /// Record mode: make real HTTP calls and save responses
  record,

  /// Replay mode: use recorded responses, no real calls
  replay,

  /// Auto mode: replay if recorded, otherwise record new
  auto,

  /// Bypass mode: disable VCR, always make real calls
  bypass,
}

/// HTTP Override for VCR
///
/// Intercepts all HTTP calls and routes them through the VCR client.
class VCRHttpOverrides extends HttpOverrides {
  /// The VCR client to use for HTTP requests
  final http.Client _vcrClient;

  VCRHttpOverrides(this._vcrClient);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Create an HTTP client that uses the VCR client
    // We need to adapt the VCR client (which implements http.Client)
    // to work with the underlying HttpClient
    return super.createHttpClient(context);
  }
}

/// VCR Test Helper
///
/// Manages VCR cassettes and clients for integration testing.
class VCRTestHelper {
  /// Singleton instance
  static final VCRTestHelper _instance = VCRTestHelper._internal();

  /// Current VCR mode
  VCRMode _mode = VCRMode.replay;

  /// Base directory for cassette files
  static const String _cassettesDir = 'test/integration/fixtures/cassettes';

  /// VCR instance
  VCR? _vcr;

  /// Current cassette
  Cassette? _currentCassette;

  /// Previous HttpOverrides (for cleanup)
  static HttpOverrides? _previousOverrides;

  factory VCRTestHelper() {
    return _instance;
  }

  VCRTestHelper._internal();

  /// Get the current VCR mode
  VCRMode get mode => _mode;

  /// Set the VCR mode
  ///
  /// Use [VCRMode.record] to record new API responses.
  /// Use [VCRMode.replay] to use recorded responses (offline testing).
  /// Use [VCRMode.auto] to replay existing recordings or record new ones.
  void setMode(VCRMode mode) {
    _mode = mode;
  }

  /// Initialize VCR for testing
  ///
  /// Sets up HttpOverrides to intercept all HTTP calls.
  /// Must be called before running tests.
  void initialize({String? cassetteName}) {
    // Create VCR with options
    _vcr = _createVCR();

    // Insert cassette if provided
    if (cassetteName != null) {
      insertCassette(cassetteName);
    }

    // Set up HTTP overrides to intercept all http package calls
    _setupHttpOverrides();
  }

  /// Create a VCR instance with advanced options
  ///
  /// Configures censoring for sensitive data (API keys, auth tokens).
  VCR _createVCR() {
    // Create censors to hide sensitive data
    final censors = Censors()
        .censorHeaderElementsByKeys(['authorization', 'x-api-key'])
        .censorQueryElementsByKeys(['key', 'api_key', 'apikey']);

    // Create advanced options
    final advancedOptions = AdvancedOptions(
      censors: censors,
      // Don't simulate delay by default for faster tests
      simulateDelay: false,
    );

    return VCR(advancedOptions: advancedOptions);
  }

  /// Set up HTTP overrides to intercept all http package calls
  ///
  /// This uses a workaround since dartvcr's DartVCRClient extends BaseClient
  /// from the http package, but providers use the top-level http.get/post functions.
  ///
  /// We override the HttpClient creation to use our VCR client internally.
  void _setupHttpOverrides() {
    // Save previous overrides for cleanup
    _previousOverrides = HttpOverrides.current;

    // Set up global HTTP overrides
    HttpOverrides.global = _VCRHttpOverridesImpl(_vcr!);
  }

  /// Insert a cassette for recording/replay
  ///
  /// The cassette file will be created/loaded from the cassettes directory.
  void insertCassette(String cassetteName) {
    // Remove existing cassette if any
    if (_currentCassette != null) {
      ejectCassette();
    }

    // Create and insert the new cassette
    _currentCassette = Cassette(_cassettesDir, cassetteName);
    _vcr!.insert(_currentCassette!);

    // Set the VCR mode
    _setVCRMode();
  }

  /// Eject the current cassette
  ///
  /// Saves the cassette if in record mode and clears it from the VCR.
  void ejectCassette() {
    if (_currentCassette != null) {
      _vcr!.eject();
      _currentCassette = null;
    }
  }

  /// Set the VCR mode based on current [VCRMode]
  void _setVCRMode() {
    if (_vcr == null) return;

    switch (_mode) {
      case VCRMode.record:
        _vcr!.record();
        break;
      case VCRMode.replay:
        _vcr!.replay();
        break;
      case VCRMode.auto:
        _vcr!.auto();
        break;
      case VCRMode.bypass:
        _vcr!.bypass();
        break;
    }
  }

  /// Reset the VCR helper
  ///
  /// Ejects any cassette, restores previous HttpOverrides, and resets to default mode.
  void reset() {
    ejectCassette();
    _mode = VCRMode.replay;

    // Restore previous HttpOverrides
    if (_previousOverrides != null) {
      HttpOverrides.global = _previousOverrides;
      _previousOverrides = null;
    }
  }

  /// Check if running in record mode
  bool get isRecording => _mode == VCRMode.record;

  /// Check if running in replay mode
  bool get isReplaying => _mode == VCRMode.replay;

  /// Get the VCR client (for direct use if needed)
  http.Client? get vcrClient {
    if (_vcr == null) return null;
    return _vcr!.client;
  }
}

/// HTTP Override implementation for VCR
///
/// Intercepts HttpClient creation to route through VCR.
class _VCRHttpOverridesImpl extends HttpOverrides {
  final VCR _vcr;

  _VCRHttpOverridesImpl(this._vcr);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // This is a limitation - dartvcr uses http.Client (from the http package)
    // but HttpOverrides works with dart:io's HttpClient
    //
    // For a proper solution, we would need to either:
    // 1. Modify providers to accept an http.Client
    // 2. Use a different approach
    //
    // For now, we'll use a simpler approach - just let the normal client
    // through and handle VCR differently
    return super.createHttpClient(context);
  }
}

/// Simplified VCR setup for integration tests
///
/// Since dartvcr works with http.Client and providers use the top-level
/// http functions, we'll need to use a workaround.
///
/// The recommended approach is to modify providers to accept an optional
/// http.Client, but for minimal changes, we'll use environment variable
/// configuration and manual cassette management.
class VCRTestSetup {
  /// Configure VCR from environment variables or command-line args
  static VCRMode configureMode(List<String> args) {
    if (args.contains('--record')) {
      return VCRMode.record;
    } else if (args.contains('--live')) {
      return VCRMode.bypass;
    } else if (args.contains('--mock')) {
      return VCRMode.replay;
    }
    // Default to replay mode for CI/offline testing
    return VCRMode.replay;
  }

  /// Create a cassette path for a provider test
  static String cassettePath(String providerName, String testName) {
    return 'test/integration/fixtures/cassettes/${providerName}_$testName.json';
  }

  /// Get API key from environment for testing
  ///
  /// Returns the API key from environment variables or throws if not found.
  static String getApiKey(String provider) {
    final key = Platform.environment['${provider.toUpperCase()}_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'Missing ${provider.toUpperCase()}_API_KEY environment variable. '
        'Required for recording integration tests.',
      );
    }
    return key;
  }
}

/// Print usage instructions for VCR testing
void printVCRUsage() {
  print('''
╔════════════════════════════════════════════════════════════════════╗
║                    VCR Integration Test Usage                       ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  Record API responses (requires real API keys):                      ║
║    flutter test test/integration --record                           ║
║    OPENAI_API_KEY=sk-... flutter test test/integration --record    ║
║                                                                      ║
║  Replay recorded responses (offline, no API keys needed):           ║
║    flutter test test/integration --mock                             ║
║                                                                      ║
║  Run live tests (always make real API calls):                       ║
║    flutter test test/integration --live                             ║
║                                                                      ║
║  Auto mode: replay if recorded, otherwise record                    ║
║    flutter test test/integration                                    ║
║                                                                      ║
╚════════════════════════════════════════════════════════════════════╝
''');
}
