import 'dart:async';
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
  final Set<String> _firedKeys = <String>{};
  String? _lastMinute;

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
    _firedKeys.clear();
    _lastMinute = null;
  }

  void _tick() {
    final now = DateTime.now();
    final day = DayNames.days[now.weekday - 1];
    final hhmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final set = schedule.days[day];
    if (set == null) return;

    if (_lastMinute != hhmm) {
      _lastMinute = hhmm;
      _firedKeys.clear();
    }

    for (var index = 0; index < set.slots.length; index++) {
      final slot = set.slots[index];
      _maybeFire(day, hhmm, slot.type, slot.start, index, 'start');
      _maybeFire(day, hhmm, slot.type, slot.end, index, 'end');
    }
  }

  Future<void> _maybeFire(
    String day,
    String hhmm,
    String kind,
    String time,
    int index,
    String edge,
  ) async {
    if (time.isEmpty) return;
    if (time != hhmm) return;
    final key = '$day|$hhmm|$kind|$index|$edge';
    if (_firedKeys.contains(key)) return;
    _firedKeys.add(key);

    final tone = kEventTones[kind];
    if (tone == null) return;
    try {
      await mopidy.playToneFor(tone, seconds: 20); // play for 20 seconds
    } catch (_) {/* ignore in dev */}
  }
}
