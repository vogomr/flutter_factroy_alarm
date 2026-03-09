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
      case 'break': return d.breakTime;
      case 'lunch': return d.lunchTime;
      case 'shift': return d.shiftTime;
    }
    return '';
  }

  void _setField(String day, String field, String value) {
    final d = _ws.days[day]!;
    switch (field) {
      case 'break': d.breakTime = value; break;
      case 'lunch': d.lunchTime = value; break;
      case 'shift': d.shiftTime = value; break;
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
        actions: [ IconButton(onPressed: _save, icon: const Icon(Icons.save)) ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [for (final d in DayNames.days) _dayView(d)],
      ),
    );
  }

  Widget _dayView(String day) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _eventRow(day, 'break', 'Break time'),
        const SizedBox(height: 12),
        _eventRow(day, 'lunch', 'Lunch time'),
        const SizedBox(height: 12),
        _eventRow(day, 'shift', 'Shift change'),
        const Spacer(),
        const Text('Each event plays for 20 seconds (dev runner).', style: TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _eventRow(String day, String field, String label) {
    final value = _getField(day, field);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(value.isEmpty ? 'Not set' : value),
        trailing: FilledButton(
          onPressed: () => _pickTime(context, day, field),
          child: const Text('Set time'),
        ),
        onLongPress: () { // clear on long-press
          _setField(day, field, '');
          setState(() {});
        },
      ),
    );
  }
}
