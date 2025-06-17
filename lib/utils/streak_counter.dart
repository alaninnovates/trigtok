import 'package:supabase_flutter/supabase_flutter.dart';

class StreakCounter {
  static int? _cachedStreak;
  static DateTime? _cachedLastUpdated;

  static Future<Map<String, dynamic>> _fetchStreakData() async {
    final response =
        await Supabase.instance.client
            .from('profiles')
            .select('streak, streak_last_updated')
            .eq('id', Supabase.instance.client.auth.currentUser!.id)
            .single();

    _cachedStreak = response['streak'] as int;
    _cachedLastUpdated =
        response['streak_last_updated'] != null
            ? DateTime.parse(response['streak_last_updated'])
            : null;

    return response;
  }

  static Future<void> _updateStreakData(int streak, DateTime timestamp) async {
    await Supabase.instance.client
        .from('profiles')
        .update({
          'streak': streak,
          'streak_last_updated': timestamp.toIso8601String(),
        })
        .eq('id', Supabase.instance.client.auth.currentUser!.id);

    _cachedStreak = streak;
    _cachedLastUpdated = timestamp;
  }

  static Future<int> increment() async {
    if (_cachedStreak == null || _cachedLastUpdated == null) {
      await _fetchStreakData();
    }
    print(
      'incrementing streak: $_cachedStreak, last updated: $_cachedLastUpdated',
    );

    final now = DateTime.now().toUtc();
    final lastUpdated =
        _cachedLastUpdated?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0).toUtc();
    final currentStreak = _cachedStreak ?? 0;

    bool isSameDay =
        lastUpdated.year == now.year &&
        lastUpdated.month == now.month &&
        lastUpdated.day == now.day;

    print(
      'Current time: $now, Last updated: $lastUpdated, Same day: $isSameDay',
    );

    if (!isSameDay) {
      final difference = now.difference(lastUpdated).inHours;

      if (difference <= 48) {
        await _updateStreakData(currentStreak + 1, now);
        return currentStreak + 1;
      } else {
        await _updateStreakData(1, now);
        return 1;
      }
    }

    return currentStreak;
  }

  static Future<int> getCurrentStreak() async {
    if (_cachedStreak == null) {
      final userData = await _fetchStreakData();
      return userData['streak'] as int;
    }
    return _cachedStreak!;
  }
}
