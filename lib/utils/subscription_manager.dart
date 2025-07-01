import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class SubscriptionManager {
  static Future<String> getCurrentPlan() async {
    var apiUrl = dotenv.env['API_URL'];
    var res = await http.get(
      Uri.parse('$apiUrl/subscription/current-plan'),
      headers: {
        'authorization':
            Supabase.instance.client.auth.currentSession?.accessToken ?? '',
      },
    );
    if (res.statusCode == 200) {
      return res.body;
    } else {
      throw Exception(
        'Failed to fetch current plan: ${res.statusCode} ${res.reasonPhrase}',
      );
    }
  }
}
