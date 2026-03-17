class DayNames {
  static const days = ['mon','tue','wed','thu','fri','sat','sun'];
  static String label(String d) => d.toUpperCase();
}

class ScheduleSlot {
  String type; // 'break', 'lunch', 'shift'
  String start;
  String end;

  ScheduleSlot({required this.type, this.start = '', this.end = ''});

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(
        type: j['type'] ?? '',
        start: j['start'] ?? '',
        end: j['end'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'start': start,
        'end': end,
      };
}

/// Per-day fields for dev UX: list of schedule slots.
class DailySet {
  List<ScheduleSlot> slots;

  DailySet({List<ScheduleSlot>? slots}) : slots = slots ?? [];

  // For backward compatibility, convert old format
  factory DailySet.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('slots')) {
      return DailySet(
        slots: (j['slots'] as List).map((s) => ScheduleSlot.fromJson(s)).toList(),
      );
    } else {
      // Old format
      final slots = <ScheduleSlot>[];
      if (j['break_start'] != null && j['break_start'].isNotEmpty) {
        slots.add(ScheduleSlot(type: 'break', start: j['break_start'], end: j['break_end'] ?? ''));
      }
      if (j['lunch_start'] != null && j['lunch_start'].isNotEmpty) {
        slots.add(ScheduleSlot(type: 'lunch', start: j['lunch_start'], end: j['lunch_end'] ?? ''));
      }
      if (j['shift_start'] != null && j['shift_start'].isNotEmpty) {
        slots.add(ScheduleSlot(type: 'shift', start: j['shift_start'], end: j['shift_end'] ?? ''));
      }
      return DailySet(slots: slots);
    }
  }

  Map<String, dynamic> toJson() => {
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  // Helper methods for old API compatibility
  String get breakStart => slots.where((s) => s.type == 'break').isNotEmpty ? slots.firstWhere((s) => s.type == 'break').start : '';
  String get breakEnd => slots.where((s) => s.type == 'break').isNotEmpty ? slots.firstWhere((s) => s.type == 'break').end : '';
  String get lunchStart => slots.where((s) => s.type == 'lunch').isNotEmpty ? slots.firstWhere((s) => s.type == 'lunch').start : '';
  String get lunchEnd => slots.where((s) => s.type == 'lunch').isNotEmpty ? slots.firstWhere((s) => s.type == 'lunch').end : '';
  String get shiftStart => slots.where((s) => s.type == 'shift').isNotEmpty ? slots.firstWhere((s) => s.type == 'shift').start : '';
  String get shiftEnd => slots.where((s) => s.type == 'shift').isNotEmpty ? slots.firstWhere((s) => s.type == 'shift').end : '';

  set breakStart(String v) {
    final existing = slots.where((s) => s.type == 'break').toList();
    if (existing.isNotEmpty) {
      existing.first.start = v;
    } else if (v.isNotEmpty) {
      slots.add(ScheduleSlot(type: 'break', start: v));
    }
  }

  set breakEnd(String v) {
    final existing = slots.where((s) => s.type == 'break').toList();
    if (existing.isNotEmpty) {
      existing.first.end = v;
    } else if (v.isNotEmpty) {
      slots.add(ScheduleSlot(type: 'break', end: v));
    }
  }

  set lunchStart(String v) {
    final existing = slots.where((s) => s.type == 'lunch').toList();
    if (existing.isNotEmpty) {
      existing.first.start = v;
    } else if (v.isNotEmpty) {
      slots.add(ScheduleSlot(type: 'lunch', start: v));
    }
  }

  set lunchEnd(String v) {
    final existing = slots.where((s) => s.type == 'lunch').toList();
    if (existing.isNotEmpty) {
      existing.first.end = v;
    } else if (v.isNotEmpty) {
      slots.add(ScheduleSlot(type: 'lunch', end: v));
    }
  }

  set shiftStart(String v) {
    final existing = slots.where((s) => s.type == 'shift').toList();
    if (existing.isNotEmpty) {
      existing.first.start = v;
    } else if (v.isNotEmpty) {
      slots.add(ScheduleSlot(type: 'shift', start: v));
    }
  }

  set shiftEnd(String v) {
    final existing = slots.where((s) => s.type == 'shift').toList();
    if (existing.isNotEmpty) {
      existing.first.end = v;
    } else if (v.isNotEmpty) {
      slots.add(ScheduleSlot(type: 'shift', end: v));
    }
  }
}

class WeeklySchedule {
  final Map<String, DailySet> days; // mon..sun
  WeeklySchedule(this.days);
  factory WeeklySchedule.empty() => WeeklySchedule({
        for (final d in DayNames.days) d: DailySet(slots: [
          ScheduleSlot(type: 'break'),
          ScheduleSlot(type: 'lunch'),
          ScheduleSlot(type: 'shift'),
        ])
      });
  factory WeeklySchedule.fromJson(Map<String,dynamic> j) {
    final map = <String,DailySet>{};
    for (final d in DayNames.days) {
      map[d] = j.containsKey(d) ? DailySet.fromJson(j[d]) : DailySet();
    }
    return WeeklySchedule(map);
  }
  Map<String,dynamic> toJson() => { for (final d in DayNames.days) d: days[d]!.toJson() };
}
