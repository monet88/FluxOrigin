import 'package:flux_origin/utils/text_processor.dart';

void main() {
  print("Testing TextProcessor.smartSplit...");

  // Test 1: Normal sentence splitting
  String text1 = "Hello world. This is a test. Another sentence.";
  List<String> chunks1 = TextProcessor.smartSplit(text1, targetSize: 20);
  print("\nTest 1 (Normal):");
  for (var chunk in chunks1) {
    print("[$chunk]");
  }
  // Expected: [Hello world.], [This is a test.], [Another sentence.]

  // Test 2: Long sentence that exceeds targetSize but has a terminator nearby
  String text2 =
      "This is a very long sentence that should ideally not be broken in the middle of a word or phrase.";
  // targetSize 30. "This is a very long sentence" is 28 chars.
  // "that should ideally not be broken" is 33 chars.
  // It should try to find a break.
  List<String> chunks2 = TextProcessor.smartSplit(text2, targetSize: 30);
  print("\nTest 2 (Long Sentence):");
  for (var chunk in chunks2) {
    print("[$chunk]");
  }

  // Test 3: Extremely long sentence with no terminators (Fallback)
  String text3 =
      "ThisIsAnExtremelyLongSentenceWithNoSpacesOrPunctuationThatWillForceAFallbackSplitAtSomePointHopefully";
  List<String> chunks3 = TextProcessor.smartSplit(text3, targetSize: 20);
  print("\nTest 3 (Fallback):");
  for (var chunk in chunks3) {
    print("[$chunk]");
  }

  // Test 4: Look forward logic
  // "A" * 90 + ". " + "B" * 10. Target 80.
  // It should NOT cut at 80. It should look forward to 92 (the dot).
  String text4 = "${"A" * 90}. ${"B" * 10}";
  List<String> chunks4 = TextProcessor.smartSplit(text4, targetSize: 80);
  print("\nTest 4 (Look Forward):");
  print("Length: ${text4.length}");
  for (var chunk in chunks4) {
    print(
        "Chunk len: ${chunk.length} -> [${chunk.substring(0, min(10, chunk.length))}...]");
  }

  if (chunks4[0].length > 80) {
    print(
        "SUCCESS: Chunk 0 extended beyond target size to include sentence terminator.");
  } else {
    print("FAIL: Chunk 0 was cut strictly at target size.");
  }
}

int min(int a, int b) => a < b ? a : b;
