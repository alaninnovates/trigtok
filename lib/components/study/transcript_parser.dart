import 'dart:convert';
import 'package:flutter/services.dart';

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
  final String assetPath;

  TranscriptParser(this.assetPath);

  Future<List<TranscriptItem>> parse() async {
    final srtContent = await rootBundle.loadString(assetPath);
    final lines = LineSplitter.split(srtContent).toList();

    final List<TranscriptItem> transcriptItems = [];
    int index = 0;
    Duration? startTime;
    Duration? endTime;
    String text = '';

    for (final line in lines) {
      if (line.isEmpty) {
        if (startTime != null && endTime != null && text.isNotEmpty) {
          transcriptItems.add(
            TranscriptItem(
              index: index,
              startTime: startTime,
              endTime: endTime,
              text: text.trim(),
            ),
          );
        }
        index = 0;
        startTime = null;
        endTime = null;
        text = '';
        continue;
      }

      if (index == 0) {
        index = int.tryParse(line) ?? 0;
      } else if (startTime == null && endTime == null) {
        final timeMatch = RegExp(
          r'(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})',
        ).firstMatch(line);
        if (timeMatch != null) {
          startTime = _parseDuration(timeMatch.group(1)!);
          endTime = _parseDuration(timeMatch.group(2)!);
        }
      } else {
        text += '$line ';
      }
    }

    // Add the last item if it exists
    if (startTime != null && endTime != null && text.isNotEmpty) {
      transcriptItems.add(
        TranscriptItem(
          index: index,
          startTime: startTime,
          endTime: endTime,
          text: text.trim(),
        ),
      );
    }

    return transcriptItems;
  }

  Duration _parseDuration(String time) {
    final parts = time.split(RegExp(r'[:,]'));
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
      milliseconds: int.parse(parts[3]),
    );
  }
}
