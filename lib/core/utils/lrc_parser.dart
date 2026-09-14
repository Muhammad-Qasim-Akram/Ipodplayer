/// LRC Parser - Parses LRC-format (line-by-line synced) lyrics
/// 
/// LRC format example:
/// [00:12.34]First line of lyrics
/// [00:15.67]Second line
/// [00:18.90][00:20.50]Line with multiple timestamps
/// 
/// This parser extracts the Duration and text for each line, handling both
/// [mm:ss.xx] and [mm:ss.xxx] formats.

class LrcLine {
  final Duration timestamp;
  final String text;

  LrcLine({required this.timestamp, required this.text});

  @override
  String toString() => 'LrcLine($timestamp, $text)';
}

class LrcParser {
  /// Parses raw LRC lyrics string and returns a sorted list of timed lines.
  /// 
  /// Returns an empty list if no LRC timestamps are found (non-synced lyrics).
  /// Returns null only if the input is null.
  static List<LrcLine>? parse(String? rawLyrics) {
    if (rawLyrics == null || rawLyrics.isEmpty) {
      return null;
    }

    final lines = <LrcLine>[];
    final timestampRegex = RegExp(r'\[(\d{1,2}):(\d{2})\.(\d{2,3})\]');

    for (final line in rawLyrics.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Find all timestamps in this line
      final matches = timestampRegex.allMatches(trimmedLine);
      if (matches.isEmpty) {
        // No timestamp found, skip this line (non-synced lyrics)
        continue;
      }

      // Extract the text (everything after the last timestamp)
      String text = trimmedLine;
      int lastTimestampEnd = 0;
      for (final match in matches) {
        lastTimestampEnd = match.end;
      }
      if (lastTimestampEnd < trimmedLine.length) {
        text = trimmedLine.substring(lastTimestampEnd).trim();
      } else {
        text = '';
      }

      // Parse each timestamp on this line (supports multiple timestamps per line)
      for (final match in matches) {
        final minutes = int.parse(match.group(1) ?? '0');
        final seconds = int.parse(match.group(2) ?? '0');
        final centiseconds = int.parse(match.group(3) ?? '0');

        // Convert centiseconds to milliseconds
        // If 3 digits, it's already in milliseconds; if 2 digits, convert from centiseconds
        final milliseconds = (match.group(3)?.length == 3)
            ? centiseconds
            : centiseconds * 10;

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        if (text.isNotEmpty) {
          lines.add(LrcLine(timestamp: duration, text: text));
        }
      }
    }

    if (lines.isEmpty) {
      return null; // No synced lyrics found
    }

    // Sort by timestamp
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return lines;
  }

  /// Finds the index of the currently active lyric line based on playback position.
  /// Returns -1 if no active line found.
  static int findActiveLineIndex(List<LrcLine> lines, Duration position) {
    int activeIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestamp <= position) {
        activeIndex = i;
      } else {
        break;
      }
    }

    return activeIndex;
  }
}
