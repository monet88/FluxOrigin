import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'http://127.0.0.1:11434/api/chat';
  // static const String _model = 'qwen2.5:7b'; // Removed hardcoded model

  static const Map<String, String> _prompts = {
    "KIEMHIEP":
        "Bạn là dịch giả kiếm hiệp lão luyện. Dùng từ Hán Việt (huynh, đệ, tại hạ...), văn phong hào hùng, cổ trang. Chiêu thức giữ nguyên âm Hán Việt.",
    "NGONTINH":
        "Bạn là dịch giả ngôn tình. Văn phong lãng mạn, nhẹ nhàng, ướt át. Xưng hô Anh - Em hoặc Chàng - Nàng tùy ngữ cảnh.",
    "KINHDOANH":
        "Bạn là chuyên gia kinh tế. Dịch văn phong trang trọng, chuyên nghiệp, dùng thuật ngữ chính xác.",
    "KHAC":
        "Bạn là một dịch giả chuyên nghiệp. Hãy dịch trôi chảy, tự nhiên, sát nghĩa gốc."
  };

  Future<String> detectGenre(String sample, String modelName) async {
    final response = await chatCompletion(
      modelName: modelName,
      messages: [
        {
          "role": "user",
          "content":
              "Bạn là một trợ lý phân loại văn học.\nHãy đọc đoạn văn bản mẫu dưới đây và xác định thể loại chính của nó.\nChỉ trả về DUY NHẤT một từ khóa trong danh sách sau: [KIEMHIEP, NGONTINH, KINHDOANH, KHOAHOC, KHAC].\nTuyệt đối không giải thích gì thêm.\n\nVăn bản mẫu:\n$sample"
        }
      ],
    );

    final genre = response.trim().toUpperCase();
    // Basic validation to ensure we got a valid key, otherwise default to KHAC
    if (_prompts.containsKey(genre)) {
      return genre;
    }
    // Try to find the keyword if the AI was chatty
    for (final key in _prompts.keys) {
      if (genre.contains(key)) {
        return key;
      }
    }
    return "KHAC";
  }

  String getSystemPrompt(String genre, String targetLanguage) {
    if (targetLanguage == 'Tiếng Việt') {
      return _prompts[genre] ?? _prompts['KHAC']!;
    } else if (targetLanguage == 'Tiếng Anh') {
      return "You are a professional translator. Translate the text into natural, fluent English. Pay attention to grammatical tense and subject-verb agreement. Avoid 'Chinglish' or 'Vietlish' phrasing.";
    } else if (targetLanguage == 'Tiếng Trung') {
      return "You are a professional translator. Translate the text into Standard Chinese (Simplified). Use appropriate idioms (Chengyu) where fitting.";
    } else {
      // Default fallback
      return "You are a professional translator. Translate the text into $targetLanguage.";
    }
  }

  Future<String> generateGlossary(String sample, String modelName) async {
    final response = await chatCompletion(modelName: modelName, messages: [
      {
        "role": "user",
        "content":
            "Hãy phân tích đoạn văn sau và liệt kê các Tên Riêng (Nhân vật, Địa danh, Môn phái, Chiêu thức) quan trọng nhất để làm Từ Điển dịch thuật.\n\nYou MUST output the CSV with exactly two columns:\nColumn 1: The EXACT English term found in the text.\nColumn 2: The Vietnamese translation (Hán Việt preferred for names/sects).\n\nDo NOT put the Vietnamese meaning in the first column.\n\nExample format:\nHeavenly Sword Sect,Thiên Kiếm Tông\nYe Chen,Diệp Trần\n\"Robert, Jr.\",Robert Con\n\nTuyệt đối KHÔNG thêm Header. Tuyệt đối không giải thích gì thêm.\n\nNội dung:\n$sample"
      }
    ], options: {
      "num_predict": 3000
    });

    // Sanitize the output
    final List<String> lines = response.split('\n');
    final StringBuffer cleanBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Reject conversational fillers
      final lower = trimmed.toLowerCase();
      if (lower.startsWith("sure") ||
          lower.startsWith("here") ||
          lower.startsWith("certainly") ||
          lower.startsWith("okay") ||
          lower.startsWith("note") ||
          lower.startsWith("of course") ||
          lower.contains("i can help") ||
          lower.contains("ai language model")) {
        continue;
      }

      // Reject lines ending with colon (often headers like "Here is the list:")
      // BUT we want to be careful not to reject "Term: Definition" if that's the format
      // So only reject if it looks like a header (no comma, no dash, just text ending in colon)
      if (trimmed.endsWith(':') &&
          !trimmed.contains(',') &&
          !trimmed.contains('-')) continue;

      // Robust parsing: Try comma, then colon, then dash
      String? original;
      String? vietnamese;
      String? definition;

      if (trimmed.contains(',')) {
        // CSV format
        final parts = trimmed.split(',');
        if (parts.length >= 2) {
          original = parts[0].trim();
          vietnamese = parts[1].trim();
          if (parts.length > 2) definition = parts.sublist(2).join(',').trim();
        }
      } else if (trimmed.contains(':')) {
        // "Term: Definition" format
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          original = parts[0].trim();
          vietnamese = parts[1].trim();
          if (parts.length > 2) definition = parts.sublist(2).join(':').trim();
        }
      } else if (trimmed.contains('-')) {
        // "Term - Definition" format
        final parts = trimmed.split('-');
        if (parts.length >= 2) {
          original = parts[0].trim();
          vietnamese = parts[1].trim();
          if (parts.length > 2) definition = parts.sublist(2).join('-').trim();
        }
      }

      if (original != null &&
          vietnamese != null &&
          original.isNotEmpty &&
          vietnamese.isNotEmpty) {
        // Basic validation: Definition shouldn't be too long (likely a sentence)
        if (vietnamese.length > 100) continue;

        // Re-construct as CSV for consistency
        cleanBuffer.writeln(
            '"$original","$vietnamese"${definition != null ? ',"$definition"' : ''}');
      }
    }

    return cleanBuffer.toString().trim();
  }

  Future<String> translateChunk(String chunk, String systemPrompt,
      String glossaryCsv, String modelName, String targetLanguage) async {
    // 1. Adaptive Prompting Logic
    final isSmallModel = modelName.toLowerCase().contains("0.5b") ||
        modelName.toLowerCase().contains("1.5b");

    String constraints = "";
    if (targetLanguage == 'Tiếng Việt') {
      constraints = """
CRITICAL OUTPUT RULES:
1. **STRATEGY:** Use Hán-Việt (Sino-Vietnamese) for all Wuxia/Cultivation terms.
2. **FORMAT:** If a term is ambiguous, write the Vietnamese first, followed by the original in brackets. Example: 'Hắc Thiết Kiếm (黑铁剑)'.
3. **NO CHINESE CHARACTERS ALONE:** Do not output Chinese characters without their Vietnamese translation.
4. **NO TRANSLATOR NOTES:** Do not add footnotes or explanations.
""";
    }

    String finalSystemPrompt;
    if (isSmallModel) {
      // Simple prompt for small models
      finalSystemPrompt =
          "You are a professional translator. Translate the following text into $targetLanguage. Output ONLY the translation. Do not repeat the input.\n$constraints";
    } else {
      // Advanced prompt for large models
      if (targetLanguage == 'Tiếng Việt') {
        finalSystemPrompt =
            "$systemPrompt\n\n$constraints\n\n### YÊU CẦU DỊCH THUẬT NÂNG CAO:\n1. Dịch CHI TIẾT từng câu, tuyệt đối KHÔNG được tóm tắt hay bỏ sót ý.\n2. Giữ nguyên sắc thái biểu cảm, các thán từ, mô tả nội tâm của nhân vật.\n3. Nếu gặp thơ ca hoặc câu đối, hãy dịch sao cho vần điệu hoặc giữ nguyên Hán Việt nếu cần.\n4. Văn phong phải trôi chảy, tự nhiên như người bản xứ viết.\n\nOUTPUT ONLY THE VIETNAMESE TRANSLATION. NO PREAMBLE.";
      } else {
        // For other languages, just use the system prompt + standard instruction
        finalSystemPrompt =
            "$systemPrompt\n\nOUTPUT ONLY THE TRANSLATION. NO PREAMBLE.";
      }
    }

    // Parse CSV to formatted string (Glossary)
    String formattedGlossary = "";
    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        glossaryCsv,
        eol: '\n',
        shouldParseNumbers: false,
      );

      final StringBuffer buffer = StringBuffer();
      for (final row in rows) {
        if (row.length >= 2) {
          final original = row[0].toString().trim();
          final vietnamese = row[1].toString().trim();
          final definition = row.length > 2 ? row[2].toString().trim() : "";

          if (original.isNotEmpty && vietnamese.isNotEmpty) {
            // Simplified glossary format for small models to avoid confusion
            if (isSmallModel) {
              buffer.write("$original: $vietnamese\n");
            } else {
              buffer.write("- Term: $original\n");
              buffer.write("  Vietnamese: $vietnamese\n");
              if (definition.isNotEmpty) {
                buffer.write("  Context/Definition: $definition\n");
              }
            }
          }
        }
      }
      formattedGlossary = buffer.toString().trim();
    } catch (e) {
      formattedGlossary = glossaryCsv; // Fallback
    }

    // Append Glossary to System Prompt
    if (formattedGlossary.isNotEmpty) {
      finalSystemPrompt += "\n\n### GLOSSARY:\n$formattedGlossary";
    }

    final rawResponse = await chatCompletion(modelName: modelName, messages: [
      {"role": "system", "content": finalSystemPrompt},
      {
        "role": "user",
        "content":
            "Translate the following text into $targetLanguage:\n\n$chunk"
      }
    ], options: {
      "timeout":
          28800000 // 8 hours, though http client timeout handles this mostly
    });

    return _cleanResponse(rawResponse, targetLanguage);
  }

  String _cleanResponse(String raw, String targetLang) {
    if (targetLang == 'Tiếng Trung') {
      return raw.trim();
    }

    String clean = raw.trim();

    // Standard cleaning (quotes)
    if (clean.startsWith('"') && clean.endsWith('"')) {
      clean = clean.substring(1, clean.length - 1);
    } else if (clean.startsWith("'") && clean.endsWith("'")) {
      clean = clean.substring(1, clean.length - 1);
    }

    // Strip prompt repetition (simple heuristic)
    final lines = clean.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first.toLowerCase();
      if (firstLine.contains("dịch đoạn văn bản") ||
          firstLine.contains("translate the following")) {
        clean = lines.sublist(1).join('\n').trim();
      }
    }

    if (targetLang == 'Tiếng Việt') {
      // Smart Cleaning for Vietnamese
      // 1. Remove parenthesized Chinese: (黑铁剑) or [黑铁剑]
      clean = clean.replaceAll(RegExp(r'\([^\)]*[\u4e00-\u9fa5]+[^\)]*\)'), '');
      clean = clean.replaceAll(RegExp(r'\[[^\]]*[\u4e00-\u9fa5]+[^\]]*\]'), '');

      // 2. Remove loose Chinese characters
      clean = clean.replaceAll(RegExp(r'[\u4e00-\u9fa5]'), '');

      // 3. Cleanup double spaces
      while (clean.contains('  ')) {
        clean = clean.replaceAll('  ', ' ');
      }
    }

    return clean.trim();
  }

  Future<String> chatCompletion(
      {required String modelName,
      required List<Map<String, String>> messages,
      Map<String, dynamic>? options}) async {
    try {
      // Convert display name to Ollama tag if needed (simple heuristic)
      // Assuming the UI passes "Qwen2.5-0.5B" or "qwen2.5:0.5b"
      // Ideally, the UI should pass the correct tag.
      // But let's ensure it's lowercased and has colon if it was dash.
      // Actually, let's trust the caller passes the correct tag or handle it in UI.
      // But for safety against "Qwen2.5-7B" format:
      final String finalModel = modelName.toLowerCase().replaceAll('-', ':');

      final body = {
        "model": finalModel,
        "messages": messages,
        "stream": false,
        if (options != null) "options": options,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        return json['message']['content'] ?? "";
      } else {
        throw Exception(
            "Ollama API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to connect to Ollama: $e");
    }
  }

  Future<List<String>> getInstalledModels() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:11434/api/tags'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> models = data['models'];
        return models.map<String>((m) => m['name'] as String).toList();
      } else {
        print('Failed to load models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting installed models: $e');
      return [];
    }
  }

  Future<bool> pullModel(
      String modelName, Function(double progress) onProgress) async {
    try {
      final request =
          http.Request('POST', Uri.parse('http://127.0.0.1:11434/api/pull'));
      request.body = jsonEncode({"name": modelName, "stream": true});
      request.headers.addAll({"Content-Type": "application/json"});

      final response = await request.send();

      if (response.statusCode == 200) {
        await response.stream.transform(utf8.decoder).listen((chunk) {
          // Ollama sends multiple JSON objects in one chunk sometimes, or split across chunks
          // We need to handle this robustly. For now, simple line splitting.
          final lines =
              chunk.split('\n').where((line) => line.trim().isNotEmpty);
          for (final line in lines) {
            try {
              final data = jsonDecode(line);
              if (data.containsKey('completed') && data.containsKey('total')) {
                final completed = data['completed'];
                final total = data['total'];
                if (total > 0) {
                  onProgress(completed / total);
                }
              } else if (data['status'] == 'success') {
                onProgress(1.0);
              }
            } catch (e) {
              // Ignore parse errors for partial chunks
            }
          }
        }).asFuture();
        return true;
      } else {
        print('Failed to pull model: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error pulling model: $e');
      return false;
    }
  }

  /// Preload a model into memory silently (fire-and-forget)
  /// Sends a minimal request to trigger model loading without generating text
  Future<void> preloadModel(String modelName) async {
    try {
      // Convert display name to Ollama tag if needed
      final String finalModel = modelName.toLowerCase().replaceAll('-', ':');

      final body = {
        "model": finalModel,
        "messages":
            [], // Empty messages list triggers loading without generation
      };

      await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // Silent success - no need to check response
      print('Model preload triggered: $finalModel');
    } catch (e) {
      // Silent failure - just log to console
      print('Model preload failed: $e');
    }
  }
}
