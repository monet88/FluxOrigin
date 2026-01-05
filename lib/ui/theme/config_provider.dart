import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import '../../services/ai_provider.dart';

class ConfigProvider extends ChangeNotifier {
  // SharedPreferences keys
  static const String _projectPathKey = 'project_path';
  static const String _selectedModelKey = 'selected_model';
  static const String _ollamaUrlKey = 'ollama_url';
  static const String _lmStudioUrlKey = 'lm_studio_url';
  static const String _aiProviderKey = 'ai_provider';
  static const String _appLanguageKey = 'app_language';
  static const String _defaultOllamaUrl = 'http://localhost:11434';
  static const String _defaultLmStudioUrl = 'http://localhost:1234';

  // Secure storage keys for cloud provider API keys
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _deepseekApiKeyKey = 'deepseek_api_key';
  static const String _zhipuApiKeyKey = 'zhipu_api_key';
  static const String _customUrlKey = 'custom_url';
  static const String _customApiKeyKey = 'custom_api_key';

  // Secure storage instance (encrypted on disk)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Use Android encrypted shared preferences
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // iOS keychain
    ),
  );

  String _projectPath = '';
  String _selectedModel = 'qwen2.5:7b'; // Default model
  String _ollamaUrl = _defaultOllamaUrl;
  String _lmStudioUrl = _defaultLmStudioUrl;
  AIProviderType _aiProvider = AIProviderType.ollama;
  String _appLanguage = 'vi'; // Default language
  bool _isLoading = true;
  bool _ollamaConnected = true; // Stealth Mode: AI provider connection status

  // Cloud provider API keys (stored securely)
  String _openaiApiKey = '';
  String _geminiApiKey = '';
  String _deepseekApiKey = '';
  String _zhipuApiKey = '';
  String _customUrl = '';
  String _customApiKey = '';

  String get projectPath => _projectPath;
  String get selectedModel => _selectedModel;
  String get ollamaUrl => _ollamaUrl;
  String get lmStudioUrl => _lmStudioUrl;
  AIProviderType get aiProvider => _aiProvider;
  String get appLanguage => _appLanguage;
  bool get isLoading => _isLoading;
  bool get ollamaConnected => _ollamaConnected;

  // Cloud provider API key getters
  String get openaiApiKey => _openaiApiKey;
  String get geminiApiKey => _geminiApiKey;
  String get deepseekApiKey => _deepseekApiKey;
  String get zhipuApiKey => _zhipuApiKey;
  String get customUrl => _customUrl;
  String get customApiKey => _customApiKey;

  /// Get the current AI URL based on selected provider
  String get currentAiUrl =>
      _aiProvider == AIProviderType.ollama ? _ollamaUrl : _lmStudioUrl;

  bool get isConfigured => _projectPath.isNotEmpty;

  String get dictionaryDir =>
      _projectPath.isEmpty ? '' : path.join(_projectPath, 'dictionary');

  ConfigProvider() {
    loadConfig();
  }

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _projectPath = prefs.getString(_projectPathKey) ?? '';
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'qwen2.5:7b';
    _ollamaUrl = prefs.getString(_ollamaUrlKey) ?? _defaultOllamaUrl;
    _lmStudioUrl = prefs.getString(_lmStudioUrlKey) ?? _defaultLmStudioUrl;
    _appLanguage = prefs.getString(_appLanguageKey) ?? 'vi';

    // Load AI provider
    final providerStr = prefs.getString(_aiProviderKey) ?? 'ollama';
    _aiProvider = AIProviderType.values.firstWhere(
      (e) => e.name == providerStr,
      orElse: () => AIProviderType.ollama,
    );

    // Load API keys from secure storage
    _openaiApiKey = await _secureStorage.read(key: _openaiApiKeyKey) ?? '';
    _geminiApiKey = await _secureStorage.read(key: _geminiApiKeyKey) ?? '';
    _deepseekApiKey = await _secureStorage.read(key: _deepseekApiKeyKey) ?? '';
    _zhipuApiKey = await _secureStorage.read(key: _zhipuApiKeyKey) ?? '';
    _customUrl = await _secureStorage.read(key: _customUrlKey) ?? '';
    _customApiKey = await _secureStorage.read(key: _customApiKeyKey) ?? '';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setProjectPath(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectPathKey, projectPath);

    _projectPath = projectPath;
    notifyListeners();
  }

  Future<void> setSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, model);

    _selectedModel = model;
    notifyListeners();
  }

  Future<void> setOllamaUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Normalize URL: remove trailing slash if present
    String normalizedUrl = url.trim();
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
    await prefs.setString(_ollamaUrlKey, normalizedUrl);

    _ollamaUrl = normalizedUrl;
    notifyListeners();
  }

  Future<void> setLmStudioUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Normalize URL: remove trailing slash if present
    String normalizedUrl = url.trim();
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
    await prefs.setString(_lmStudioUrlKey, normalizedUrl);

    _lmStudioUrl = normalizedUrl;
    notifyListeners();
  }

  Future<void> setAIProvider(AIProviderType provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiProviderKey, provider.name);

    _aiProvider = provider;
    notifyListeners();
  }

  Future<void> setAppLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLanguageKey, lang);

    _appLanguage = lang;
    notifyListeners();
  }

  /// Stealth Mode: Check AI provider connection status silently
  /// Updates ollamaConnected state without showing any dialogs
  Future<void> checkOllamaHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$currentAiUrl/'))
          .timeout(const Duration(seconds: 3));
      _ollamaConnected = (response.statusCode == 200);
    } catch (e) {
      _ollamaConnected = false;
    }
    notifyListeners();
  }

  // ========== Cloud Provider API Key Setters (Secure Storage) ==========

  /// Set OpenAI API key (stored in encrypted keychain/keystore)
  Future<void> setOpenaiApiKey(String key) async {
    if (key.isEmpty) {
      await _secureStorage.delete(key: _openaiApiKeyKey);
    } else {
      await _secureStorage.write(key: _openaiApiKeyKey, value: key);
    }
    _openaiApiKey = key;
    notifyListeners();
  }

  /// Set Google Gemini API key (stored in encrypted keychain/keystore)
  Future<void> setGeminiApiKey(String key) async {
    if (key.isEmpty) {
      await _secureStorage.delete(key: _geminiApiKeyKey);
    } else {
      await _secureStorage.write(key: _geminiApiKeyKey, value: key);
    }
    _geminiApiKey = key;
    notifyListeners();
  }

  /// Set DeepSeek API key (stored in encrypted keychain/keystore)
  Future<void> setDeepseekApiKey(String key) async {
    if (key.isEmpty) {
      await _secureStorage.delete(key: _deepseekApiKeyKey);
    } else {
      await _secureStorage.write(key: _deepseekApiKeyKey, value: key);
    }
    _deepseekApiKey = key;
    notifyListeners();
  }

  /// Set Zhipu/Z.AI API key (stored in encrypted keychain/keystore)
  Future<void> setZhipuApiKey(String key) async {
    if (key.isEmpty) {
      await _secureStorage.delete(key: _zhipuApiKeyKey);
    } else {
      await _secureStorage.write(key: _zhipuApiKeyKey, value: key);
    }
    _zhipuApiKey = key;
    notifyListeners();
  }

  /// Set custom provider base URL (stored in encrypted keychain/keystore)
  Future<void> setCustomUrl(String url) async {
    String normalizedUrl = url.trim();
    if (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
    if (normalizedUrl.isEmpty) {
      await _secureStorage.delete(key: _customUrlKey);
    } else {
      await _secureStorage.write(key: _customUrlKey, value: normalizedUrl);
    }
    _customUrl = normalizedUrl;
    notifyListeners();
  }

  /// Set custom provider API key (stored in encrypted keychain/keystore)
  Future<void> setCustomApiKey(String key) async {
    if (key.isEmpty) {
      await _secureStorage.delete(key: _customApiKeyKey);
    } else {
      await _secureStorage.write(key: _customApiKeyKey, value: key);
    }
    _customApiKey = key;
    notifyListeners();
  }

  /// Clear all stored API keys (for logout/reset)
  Future<void> clearApiKeys() async {
    await _secureStorage.delete(key: _openaiApiKeyKey);
    await _secureStorage.delete(key: _geminiApiKeyKey);
    await _secureStorage.delete(key: _deepseekApiKeyKey);
    await _secureStorage.delete(key: _zhipuApiKeyKey);
    await _secureStorage.delete(key: _customUrlKey);
    await _secureStorage.delete(key: _customApiKeyKey);

    _openaiApiKey = '';
    _geminiApiKey = '';
    _deepseekApiKey = '';
    _zhipuApiKey = '';
    _customUrl = '';
    _customApiKey = '';
    notifyListeners();
  }
}
