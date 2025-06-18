import 'package:supabase_flutter/supabase_flutter.dart';

class StreakCounter {
  static Future<List<DateTime>> getStreaks() async {
    var res = await Supabase.instance.client.rpc('get_streak_days');
    if (res == null) {
      throw Exception('Failed to fetch streaks');
    }
    return (res as List<dynamic>)
        .map((e) => DateTime.parse(e['study_date']).toUtc())
        .toList();
  }

  static Future<int> getCurrentStreakLength() async {
    var res = await Supabase.instance.client.rpc('get_current_streak_length');
    if (res == null) {
      throw Exception('Failed to fetch current streak length');
    }
    return res as int;
  }
}
