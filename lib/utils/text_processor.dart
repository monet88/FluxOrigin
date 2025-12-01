import 'dart:math';

class TextProcessor {
  static const int _targetChunkSize = 1000;
  static const int _lookBackLimit = 300;
  static const List<String> _safeChars = ['.', '\n', '!', '?', '”', '"'];

  /// Splits text into chunks of approximately [targetSize] characters,
  /// respecting sentence boundaries.
  static List<String> smartSplit(String text,
      {int targetSize = _targetChunkSize}) {
    final List<String> chunks = [];
    int currentPos = 0;
    final int length = text.length;

    while (currentPos < length) {
      int endPos = currentPos + targetSize;

      if (endPos >= length) {
        endPos = length;
      } else {
        // Look back logic
        int safeSpot = -1;
        for (int i = 0; i < _lookBackLimit; i++) {
          final int checkPos = endPos - i;
          if (checkPos <= currentPos) break; // Don't go back before start

          final String char = text[checkPos];
          if (_safeChars.contains(char)) {
            safeSpot = checkPos + 1; // Include the punctuation
            break;
          }
        }

        if (safeSpot != -1) {
          endPos = safeSpot;
        } else {
          // Fallback to nearest space
          for (int i = 0; i < 100; i++) {
            final int checkPos = endPos - i;
            if (checkPos <= currentPos) break;

            if (text[checkPos] == ' ') {
              endPos = checkPos;
              break;
            }
          }
        }
      }

      final String chunk = text.substring(currentPos, endPos).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      currentPos = endPos;
    }

    return chunks;
  }

  /// Creates a sample text for analysis by taking head, mid, and tail sections.
  static String createSample(String text) {
    const int headSize = 4000;
    const int midSize = 3000;
    const int tailSize = 3000;
    final int totalLen = text.length;

    if (totalLen <= (headSize + midSize + tailSize)) {
      return text;
    }

    String combinedSample = "";

    // 1. Head
    int safeHeadEnd = _findSafeCutBackwards(text, headSize);
    combinedSample +=
        "--- [PHẦN MỞ ĐẦU] ---\n${text.substring(0, safeHeadEnd)}\n\n";

    // 2. Mid
    final int midPoint = (totalLen / 2).floor();
    int safeMidStart = _findSafeCutForward(text, midPoint);
    int safeMidEnd = _findSafeCutBackwards(text, safeMidStart + midSize);

    // Ensure we don't go out of bounds or overlap weirdly if text is short (though handled by first check)
    if (safeMidStart < safeHeadEnd) safeMidStart = safeHeadEnd;
    if (safeMidEnd > totalLen) safeMidEnd = totalLen;

    if (safeMidEnd > safeMidStart) {
      combinedSample +=
          "--- [PHẦN GIỮA TRUYỆN] ---\n... ${text.substring(safeMidStart, safeMidEnd)} ...\n\n";
    }

    // 3. Tail
    int startTail = totalLen - tailSize;
    if (startTail < safeMidEnd) startTail = safeMidEnd;

    int safeTailStart = _findSafeCutForward(text, startTail);
    combinedSample +=
        "--- [PHẦN KẾT THÚC] ---\n... ${text.substring(safeTailStart, totalLen)}";

    return combinedSample;
  }

  static int _findSafeCutBackwards(String text, int limitIndex) {
    for (int i = 0; i < 500; i++) {
      final int idx = limitIndex - i;
      if (idx < 0) return 0;

      if (_safeChars.contains(text[idx])) {
        return idx + 1;
      }
    }
    // Fallback to space
    final int lastSpace = text.lastIndexOf(' ', limitIndex);
    return lastSpace != -1 ? lastSpace : limitIndex;
  }

  static int _findSafeCutForward(String text, int startIndex) {
    for (int i = 0; i < 500; i++) {
      final int idx = startIndex + i;
      if (idx >= text.length) return text.length;

      if (_safeChars.contains(text[idx])) {
        return idx + 1;
      }
    }
    // Fallback to space
    final int firstSpace = text.indexOf(' ', startIndex);
    return firstSpace != -1 ? firstSpace + 1 : startIndex;
  }
}
