class DayNames {
  static const days = ['mon','tue','wed','thu','fri','sat','sun'];
  static String label(String d) => d.toUpperCase();
}

/// Per-day fields for dev UX: break/lunch/shift (24h string "HH:MM").
class DailySet {
  String breakTime;
  String lunchTime;
  String shiftTime;
  DailySet({this.breakTime='', this.lunchTime='', this.shiftTime=''});
  factory DailySet.fromJson(Map<String,dynamic> j) => DailySet(
    breakTime: j['break'] ?? '', lunchTime: j['lunch'] ?? '', shiftTime: j['shift'] ?? '',
  );
  Map<String,dynamic> toJson() => {'break':breakTime, 'lunch':lunchTime, 'shift':shiftTime};
}

class WeeklySchedule {
  final Map<String, DailySet> days; // mon..sun
  WeeklySchedule(this.days);
  factory WeeklySchedule.empty() => WeeklySchedule({ for (final d in DayNames.days) d: DailySet() });
  factory WeeklySchedule.fromJson(Map<String,dynamic> j) {
    final map = <String,DailySet>{};
    for (final d in DayNames.days) {
      map[d] = j.containsKey(d) ? DailySet.fromJson(j[d]) : DailySet();
    }
    return WeeklySchedule(map);
  }
  Map<String,dynamic> toJson() => { for (final d in DayNames.days) d: days[d]!.toJson() };
}
