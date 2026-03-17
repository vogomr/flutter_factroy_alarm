import 'package:flutter/material.dart';

import '../schedules/server_schedule_store.dart';
import '../schedules/weekly_models.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});
  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> with SingleTickerProviderStateMixin {
  final _store = ServerScheduleStore();
  WeeklySchedule _ws = WeeklySchedule.empty();
  late TabController _tab;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: DayNames.days.length, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final schedule = await _store.load();
      if (!mounted) return;
      setState(() {
        _ws = schedule;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }
  }

  String _getField(String day, int index, String field) {
    final slots = _ws.days[day]!.slots;
    if (index >= slots.length) return '';
    final slot = slots[index];
    switch (field) {
      case 'start': return slot.start;
      case 'end': return slot.end;
    }
    return '';
  }

  void _setField(String day, int index, String field, String value) {
    final slots = _ws.days[day]!.slots;
    if (index >= slots.length) return;
    final slot = slots[index];
    switch (field) {
      case 'start': slot.start = value; break;
      case 'end': slot.end = value; break;
    }
  }

  Future<void> _pickTime(BuildContext ctx, String day, int index, String field) async {
    final current = _getField(day, index, field);
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
    _setField(day, index, field, _fmt(picked));
    setState(() {});
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _store.save(_ws);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule saved to server')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _removeSlot(String day, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove slot'),
        content: const Text('Remove this schedule slot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    _ws.days[day]!.slots.removeAt(index);
    setState(() {});
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

    // Create slot first; users can set start/end later.
    _ws.days[day]!.slots.add(ScheduleSlot(type: eventType));
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot added. Set Start/End only if needed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _addScheduleSlot,
            icon: const Icon(Icons.add, color: Colors.black87),
          ),
          IconButton(
            onPressed: _loading || _saving ? null : _save,
            icon: const Icon(Icons.save, color: Colors.black87),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [for (final d in DayNames.days) Tab(text: DayNames.label(d))],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_loadError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load server schedule.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadSchedule,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

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
    final slots = _ws.days[day]!.slots;
    return Padding(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      child: Column(children: [
        Expanded(
          child: slots.isEmpty
              ? Center(child: Text('No slots yet. Tap "Add Slot" below.', style: TextStyle(color: Colors.black54, fontSize: isSmall ? 12 : 14)))
              : ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) => _slotCard(day, index, isSmall),
                ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _saving ? null : _addScheduleSlot,
          icon: const Icon(Icons.add),
          label: const Text('Add Slot'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F2937),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _saving ? 'Saving to server...' : 'Tap a time to update. Saved schedules run on the Debian server.',
          style: TextStyle(color: Colors.black54, fontSize: isSmall ? 12 : 14),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _slotCard(String day, int index, bool isSmall) {
    final slot = _ws.days[day]!.slots[index];
    final label = slot.type == 'break' ? 'Break time' : slot.type == 'lunch' ? 'Lunch time' : 'Shift change';
    final color = slot.type == 'break' ? Colors.blue : slot.type == 'lunch' ? Colors.amber : Colors.green;
    final start = _getField(day, index, 'start');
    final end = _getField(day, index, 'end');
    return Card(
      shadowColor: Colors.black12,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.only(bottom: isSmall ? 8 : 12),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isSmall ? 14 : 16,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(Icons.schedule, color: color, size: isSmall ? 16 : 18),
                ),
                SizedBox(width: isSmall ? 8 : 12),
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeSlot(day, index),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 10 : 14),
            _timeRow(day, index, 'Start', start, color, isSmall),
            SizedBox(height: isSmall ? 6 : 10),
            _timeRow(day, index, 'End', end, color, isSmall),
          ],
        ),
      ),
    );
  }

  Widget _timeRow(String day, int index, String which, String value, Color color, bool isSmall) {
    final field = which.toLowerCase();
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
          style: FilledButton.styleFrom(backgroundColor: color, padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 10, horizontal: isSmall ? 10 : 12)),
          onPressed: () => _pickTime(context, day, index, field),
          child: Text('Set time', style: TextStyle(fontSize: isSmall ? 12 : 14)),
        ),
      ],
    );
  }
}
