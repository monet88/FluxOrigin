import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigProvider extends ChangeNotifier {
  static const String _inputPathKey = 'input_path';
  static const String _outputPathKey = 'output_path';

  String _inputPath = '';
  String _outputPath = '';
  bool _isLoading = true;

  String get inputPath => _inputPath;
  String get outputPath => _outputPath;
  bool get isLoading => _isLoading;

  bool get isConfigured => _inputPath.isNotEmpty && _outputPath.isNotEmpty;

  ConfigProvider() {
    loadConfig();
  }

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _inputPath = prefs.getString(_inputPathKey) ?? '';
    _outputPath = prefs.getString(_outputPathKey) ?? '';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPaths(String input, String output) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inputPathKey, input);
    await prefs.setString(_outputPathKey, output);

    _inputPath = input;
    _outputPath = output;
    notifyListeners();
  }
}
