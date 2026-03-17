import 'package:flutter/material.dart';
import '../schedules/weekly_models.dart';
import '../schedules/dev_schedule_store.dart';
import '../schedules/scheduler_runner.dart';
import '../api/mopidy_api.dart';

class SchedulesWeekPage extends StatefulWidget {
  const SchedulesWeekPage({super.key});
  @override State<SchedulesWeekPage> createState() => _SchedulesWeekPageState();
}

class _SchedulesWeekPageState extends State<SchedulesWeekPage> with SingleTickerProviderStateMixin {
  final _store = DevScheduleStore();
  late WeeklySchedule _ws;
  late TabController _tab;
  late SchedulerRunner _runner;

  @override
  void initState() {
    super.initState();
    _ws = _store.load();
    _tab = TabController(length: DayNames.days.length, vsync: this);
    _runner = SchedulerRunner(mopidy: MopidyAPI(), schedule: _ws)..start();
  }

  @override
  void dispose() {
    _runner.stop();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext ctx, String day, String field) async {
    final current = _getField(day, field);
    final initial = _parseTime(current) ?? const TimeOfDay(hour: 12, minute: 0);
    final picked = await showTimePicker(
      context: ctx,
      initialTime: initial,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    _setField(day, field, _fmt(picked));
    setState(() {});
  }

  String _getField(String day, String field) {
    final d = _ws.days[day]!;
    switch (field) {
      case 'break_start': return d.breakStart;
      case 'break_end': return d.breakEnd;
      case 'lunch_start': return d.lunchStart;
      case 'lunch_end': return d.lunchEnd;
      case 'shift_start': return d.shiftStart;
      case 'shift_end': return d.shiftEnd;
    }
    return '';
  }

  void _setField(String day, String field, String value) {
    final d = _ws.days[day]!;
    switch (field) {
      case 'break_start': d.breakStart = value; break;
      case 'break_end': d.breakEnd = value; break;
      case 'lunch_start': d.lunchStart = value; break;
      case 'lunch_end': d.lunchEnd = value; break;
      case 'shift_start': d.shiftStart = value; break;
      case 'shift_end': d.shiftEnd = value; break;
    }
  }

  TimeOfDay? _parseTime(String s) {
    if (s.isEmpty) return null;
    final parts = s.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _save() {
    _store.save(_ws);
    _runner.update(_ws);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _addScheduleSlot() async {
    final day = DayNames.days[_tab.index];
    final eventType = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('New Schedule Slot'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'break'),
            child: const Text('Break'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'lunch'),
            child: const Text('Lunch'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'shift'),
            child: const Text('Shift'),
          ),
        ],
      ),
    );

    if (eventType == null) return;

    final start = await _pickTimeDialog('Start time');
    if (start == null) return;
    final end = await _pickTimeDialog('End time');
    if (end == null) return;

    _setField(day, '${eventType}_start', start);
    _setField(day, '${eventType}_end', end);
    setState(() {});
  }

  Future<String?> _pickTimeDialog(String title) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return _fmt(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule (Dev)'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [for (final d in DayNames.days) Tab(text: DayNames.label(d))],
        ),
        actions: [
          IconButton(onPressed: _addScheduleSlot, icon: const Icon(Icons.add)),
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          return TabBarView(
            controller: _tab,
            children: [for (final d in DayNames.days) _dayView(d, isSmall)],
          );
        },
      ),
    );
  }

  Widget _dayView(String day, bool isSmall) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(children: [
        _eventCard(day, 'break', 'Break time', Colors.blue, isSmall),
        SizedBox(height: isSmall ? 8 : 12),
        _eventCard(day, 'lunch', 'Lunch time', Colors.amber, isSmall),
        SizedBox(height: isSmall ? 8 : 12),
        _eventCard(day, 'shift', 'Shift change', Colors.green, isSmall),
        const Spacer(),
        Text('Each event plays for 20 seconds (dev runner).', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 14)),
      ]),
    );
  }

  Widget _eventCard(String day, String eventKey, String label, Color color, bool isSmall) {
    final start = _getField(day, '${eventKey}_start');
    final end = _getField(day, '${eventKey}_end');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isSmall ? 14 : 16,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(Icons.schedule, color: color, size: isSmall ? 16 : 18),
                ),
                SizedBox(width: isSmall ? 8 : 12),
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmall ? 14 : 16)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Remove slot'),
                        content: const Text('Clear this schedule slot?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    _setField(day, '${eventKey}_start', '');
                    _setField(day, '${eventKey}_end', '');
                    setState(() {});
                  },
                ),
              ],
            ),
            SizedBox(height: isSmall ? 10 : 14),
            _timeRow(day, eventKey, 'Start', start, color, isSmall),
            SizedBox(height: isSmall ? 6 : 8),
            _timeRow(day, eventKey, 'End', end, color, isSmall),
          ],
        ),
      ),
    );
  }

  Widget _timeRow(String day, String eventKey, String which, String value, Color color, bool isSmall) {
    final field = '${eventKey}_${which.toLowerCase()}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(which, style: TextStyle(fontSize: isSmall ? 10 : 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? 'Not set' : value, style: TextStyle(fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => _pickTime(context, day, field),
          child: Text('Set $which', style: TextStyle(fontSize: isSmall ? 12 : 14)),
        ),
      ],
    );
  }
}
