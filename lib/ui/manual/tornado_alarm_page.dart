import 'package:flutter/material.dart';
import '../../api/mopidy_api.dart';

class TornadoAlarmPage extends StatefulWidget {
  const TornadoAlarmPage({super.key});
  @override State<TornadoAlarmPage> createState() => _TornadoAlarmPageState();
}

class _TornadoAlarmPageState extends State<TornadoAlarmPage> {
  final mopidy = MopidyAPI();
  double _volume = 85;
  bool _repeat = true;  // loop by default

  Future<void> _start() async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm TORNADO Alarm'),
        content: const Text('Are you sure you want to trigger the Tornado alarm?'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('Trigger')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await mopidy.setRepeat(_repeat);
      await mopidy.playTone('tornado_alarm.wav', volume: _volume.round());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tornado alarm started ${_repeat ? "(repeating)" : ""}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Start failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _stop() async {
    try {
      await mopidy.setRepeat(false);
      await mopidy.stop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stop failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFB00020);
    return Scaffold(
      appBar: AppBar(
        title: const Text('TORNADO Alarm'),
        backgroundColor: danger,
        actions: [ IconButton(onPressed: _stop, icon: const Icon(Icons.stop)) ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              color: danger.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: danger, size: 48),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Tornado Alarm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: danger)),
                          Text('Use this only in case of emergency. This will play a loud repeating alarm.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              value: _repeat,
              onChanged: (v)=>setState(()=>_repeat=v),
              title: const Text('Repeat (loop)'),
              subtitle: const Text('If ON, the tone loops until STOP is pressed'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.volume_up),
                const SizedBox(width: 12),
                const Text('Volume', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(), Text('${_volume.round()}%'),
              ],
            ),
            Slider(
              value: _volume, min: 0, max: 100, divisions: 20,
              activeColor: danger,
              onChanged: (v)=>setState(()=>_volume=v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                onPressed: _start,
                child: const Text('START TORNADO ALARM', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('STOP'),
                ),
                onPressed: _stop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
