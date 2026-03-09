import 'package:flutter/material.dart';
import '../api/mopidy_api.dart';
import 'manual/tornado_alarm_page.dart';
import 'schedules_page.dart';
import 'schedules_week_page.dart';
import 'widgets/tone_button.dart';
import 'widgets/status_banner.dart';

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }

class _HomePageState extends State<HomePage> {
  final mopidy = MopidyAPI();
  bool busy = false;

  Future<void> _play(String file) async {
    setState(() => busy = true);
    try {
      await mopidy.playTone(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing: $file')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1400 ? 4 : width >= 1000 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Alarm Controller'),
        actions: [
          IconButton(tooltip: 'Refresh Mopidy', onPressed: () => mopidy.ping(), icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Audio Test', onPressed: () => _play('lunch_bell.wav'), icon: const Icon(Icons.volume_up)),
          PopupMenuButton<String>(
            tooltip: 'More',
            itemBuilder: (menuCtx) => [
              const PopupMenuItem(value: 'schedules', child: Text('Schedules')), 
              const PopupMenuItem(value: 'weekly', child: Text('Weekly (dev)')),
              const PopupMenuItem(value: 'tornado', child: Text('Manual Tornado Alarm')),
            ],
            onSelected: (v) {
              switch (v) {
                case 'schedules':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesPage()));
                  break;
                case 'weekly':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesWeekPage()));
                  break;
                case 'tornado':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TornadoAlarmPage()));
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        StatusBanner(mopidy: mopidy),
        const SizedBox(height: 12),
        Expanded(child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            ToneButton(label: 'Lunch Bell', file: 'lunch_bell.wav', onTap: _play, color: Colors.orange),
            ToneButton(label: 'Shift Change', file: 'shift_change.wav', onTap: _play, color: const Color.fromARGB(255, 50, 80, 247)),
            ToneButton(label: 'Energy Alarm', file: 'energy_alarm.wav', onTap: _play, color: const Color.fromARGB(255, 204, 4, 4)),
            ToneButton.emergency(label: 'TORNADO', file: 'tornado_alarm.wav', onTap: _play),
          ],
        )),
        if (busy) const LinearProgressIndicator(minHeight: 4),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesPage())),
              icon: const Icon(Icons.schedule),
              label: const Text('Schedules'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TornadoAlarmPage())),
              icon: const Icon(Icons.warning),
              label: const Text('Manual Tornado'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ]),
    );
  }
}
