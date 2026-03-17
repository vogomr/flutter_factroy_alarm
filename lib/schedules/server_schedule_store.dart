import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'weekly_models.dart';

class ServerScheduleStore {
  Uri _scheduleUri() {
    final base = AppConfig.scheduleBaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base/api/schedule');
  }

  Future<WeeklySchedule> load() async {
    final response = await http.get(
      _scheduleUri(),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Schedule load failed: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeeklySchedule.fromJson(json);
  }

  Future<void> save(WeeklySchedule schedule) async {
    final response = await http.post(
      _scheduleUri(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(schedule.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Schedule save failed: ${response.statusCode} ${response.body}');
    }
  }
}