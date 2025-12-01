import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'http://127.0.0.1:11434/api/chat';
  static const String _model = 'qwen2.5:7b'; // Default model, can be changed

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

  Future<String> detectGenre(String sample) async {
    final response = await _chatCompletion(
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
      return _prompts[genre]!;
    }
    // Try to find the keyword if the AI was chatty
    for (final key in _prompts.keys) {
      if (genre.contains(key)) {
        return _prompts[key]!;
      }
    }
    return _prompts["KHAC"]!;
  }

  Future<String> generateGlossary(String sample) async {
    final response = await _chatCompletion(messages: [
      {
        "role": "user",
        "content":
            "Hãy phân tích đoạn văn sau và liệt kê các Tên Riêng (Nhân vật, Địa danh, Môn phái, Chiêu thức) quan trọng nhất để làm Từ Điển dịch thuật.\n\nĐịnh dạng trả về: Chỉ liệt kê dạng text, mỗi từ một dòng: Tên Gốc - Tên Hán Việt.\nVí dụ:\nLi Feng - Lý Phong\nAzure Dragon - Thanh Long\n\nTuyệt đối không giải thích gì thêm.\n\nNội dung:\n$sample"
      }
    ], options: {
      "num_predict": 3000
    });
    return response.trim();
  }

  Future<String> translateChunk(
      String chunk, String systemPrompt, String glossary) async {
    final fullSystemPrompt =
        "$systemPrompt\n\n### BẮT BUỘC TUÂN THỦ TỪ ĐIỂN (GLOSSARY):\n$glossary\n\n### YÊU CẦU DỊCH THUẬT NÂNG CAO:\n1. Dịch CHI TIẾT từng câu, tuyệt đối KHÔNG được tóm tắt hay bỏ sót ý.\n2. Giữ nguyên sắc thái biểu cảm, các thán từ, mô tả nội tâm của nhân vật.\n3. Nếu gặp thơ ca hoặc câu đối, hãy dịch sao cho vần điệu hoặc giữ nguyên Hán Việt nếu cần.\n4. Văn phong phải trôi chảy, tự nhiên như người bản xứ viết.";

    return await _chatCompletion(messages: [
      {"role": "system", "content": fullSystemPrompt},
      {
        "role": "user",
        "content": "Dịch đoạn văn bản sau sang tiếng Việt:\n\n$chunk"
      }
    ], options: {
      "timeout":
          28800000 // 8 hours, though http client timeout handles this mostly
    });
  }

  Future<String> _chatCompletion(
      {required List<Map<String, String>> messages,
      Map<String, dynamic>? options}) async {
    try {
      final body = {
        "model": _model,
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
}
