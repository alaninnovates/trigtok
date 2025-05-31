class TranscriptItem {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;

  TranscriptItem({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  @override
  String toString() {
    return 'TranscriptItem(index: $index, startTime: $startTime, endTime: $endTime, text: $text)';
  }
}

class TranscriptParser {
  static List<TranscriptItem> parseTranscript(List<dynamic> jsonString) {
    return jsonString.map((jsonItem) {
      final start = jsonItem['start'];
      final end = jsonItem['end'];
      return TranscriptItem(
        index: jsonItem['index'],
        startTime: Duration(
          hours: start['hours'] ?? 0,
          minutes: start['minutes'] ?? 0,
          seconds: start['seconds'] ?? 0,
          milliseconds: start['milliseconds'] ?? 0,
        ),
        endTime: Duration(
          hours: end['hours'] ?? 0,
          minutes: end['minutes'] ?? 0,
          seconds: end['seconds'] ?? 0,
          milliseconds: end['milliseconds'] ?? 0,
        ),
        text: jsonItem['text'] ?? '',
      );
    }).toList();
  }
}
