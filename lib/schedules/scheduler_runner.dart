import 'dart:async';
import 'package:intl/intl.dart';
import '../api/mopidy_api.dart';
import 'weekly_models.dart';

/// Map event -> tone filename (adjust names to your media files as needed).
const Map<String, String> kEventTones = {
  'break': 'energy_alarm.wav',
  'lunch': 'lunch_bell.wav',
  'shift': 'shift_change.wav',
};

class SchedulerRunner {
  final MopidyAPI mopidy;
  WeeklySchedule schedule;
  Timer? _timer;
  String? _lastFiredKey; // e.g., mon|12:00|lunch

  SchedulerRunner({required this.mopidy, required this.schedule});

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void update(WeeklySchedule ws) {
    schedule = ws;
    _lastFiredKey = null;
  }

  void _tick() {
    final now = DateTime.now();
    final day = DateFormat('E').format(now).toLowerCase().substring(0,3); // mon..sun
    final hhmm = DateFormat('HH:mm').format(now);
    final set = schedule.days[day];
    if (set == null) return;

    _maybeFire(day, hhmm, 'break', set.breakTime);
    _maybeFire(day, hhmm, 'lunch', set.lunchTime);
    _maybeFire(day, hhmm, 'shift', set.shiftTime);
  }

  Future<void> _maybeFire(String day, String hhmm, String kind, String time) async {
    if (time.isEmpty) return;
    if (time != hhmm) return;
    final key = '$day|$hhmm|$kind';
    if (_lastFiredKey == key) return; // prevent re-fire this minute
    _lastFiredKey = key;

    final tone = kEventTones[kind];
    if (tone == null) return;
    try {
      await mopidy.playToneFor(tone, seconds: 20); // play for 20 seconds
    } catch (_) {/* ignore in dev */}
  }
}
