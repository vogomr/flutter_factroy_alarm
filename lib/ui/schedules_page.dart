import 'package:flutter/material.dart';

class SchedulesPage extends StatefulWidget { const SchedulesPage({super.key}); @override State<SchedulesPage> createState() => _SchedulesPageState(); }

class _SchedulesPageState extends State<SchedulesPage> {
  final List<Map<String, String>> items = [
    {"time": "12:00", "tone": "lunch_bell.wav"},
    {"time": "15:00", "tone": "shift_change.wav"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Schedules")),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(it["time"]!),
            subtitle: Text(it["tone"]!),
            trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => items.removeAt(i))),
            onTap: () => _edit(i),
          );
        },
      ),
    );
  }

  void _add() async { final edited = await _openEditor(); if (edited != null) setState(() => items.add(edited)); }
  void _edit(int i) async { final edited = await _openEditor(items[i]); if (edited != null) setState(() => items[i] = edited); }

  Future<Map<String, String>?> _openEditor([Map<String, String>? item]) async {
    final time = TextEditingController(text: item?["time"]);
    final tone = TextEditingController(text: item?["tone"]);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Schedule'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: time, decoration: const InputDecoration(labelText: 'Time (HH:MM)')),
          TextField(controller: tone, decoration: const InputDecoration(labelText: 'Tone filename')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, {"time": time.text, "tone": tone.text}), child: const Text('Save')),
        ],
      ),
    );
  }
}
