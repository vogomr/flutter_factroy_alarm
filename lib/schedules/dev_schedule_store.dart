import 'dart:convert';
import 'dart:html' as html;
import 'weekly_models.dart';

class DevScheduleStore {
  static const _kKey = 'weekly_schedule_v1';

  WeeklySchedule load() {
    final s = html.window.localStorage[_kKey];
    if (s == null) return WeeklySchedule.empty();
    try { return WeeklySchedule.fromJson(jsonDecode(s)); }
    catch (_) { return WeeklySchedule.empty(); }
  }

  void save(WeeklySchedule ws) {
    html.window.localStorage[_kKey] = jsonEncode(ws.toJson());
  }
}
