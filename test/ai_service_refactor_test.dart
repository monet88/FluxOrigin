import 'package:flutter_test/flutter_test.dart';
import 'package:flux_origin/services/ai_service.dart';

void main() {
  group('AIService Cleanup Logic', () {
    final aiService = AIService();

    test('Removes English suffixes (Fallback)', () {
      // Scenario: AI translates "Mystic Cloud" but leaves "Hall"
      const input = "Huyền Vân Hall";
      const expected = "Huyền Vân";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Removes English suffixes with space', () {
      const input = "Thiên Kiếm Sect";
      const expected = "Thiên Kiếm";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Removes trailing punctuation loops', () {
      const input = "Cửu Dương，。，。，。";
      const expected = "Cửu Dương.";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Removes trailing dots loop', () {
      const input = "Nội dung......";
      const expected = "Nội dung.";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Removes parenthesized Chinese', () {
      const input = "Huyền Vân Điện (玄云殿)";
      const expected = "Huyền Vân Điện";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Removes square bracket Chinese', () {
      const input = "Huyền Vân Điện [玄云殿]";
      const expected = "Huyền Vân Điện";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Replaces Chinese punctuation', () {
      const input = "Xin chào，thế giới。Đây là thử nghiệm：thành công？Tuyệt vời！";
      const expected =
          "Xin chào, thế giới. Đây là thử nghiệm: thành công? Tuyệt vời!";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Replaces Chinese quotes', () {
      const input = "Anh ấy nói: “Xin chào”";
      const expected = 'Anh ấy nói: "Xin chào"';
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });

    test('Removes rare Chinese symbols', () {
      const input = "Tiêu đề\u3000Mới"; // Ideographic space
      const expected = "Tiêu đềMới";
      final result = aiService.cleanResponse(input, 'Tiếng Việt');
      expect(result, expected);
    });
  });
}
