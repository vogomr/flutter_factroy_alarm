import 'dart:async';
import 'package:flutter/material.dart';
import '../../api/mopidy_api.dart';

class StatusBanner extends StatefulWidget {
  final MopidyAPI mopidy;
  const StatusBanner({super.key, required this.mopidy});

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  Timer? _timer;
  bool online = false;
  String now = '-';

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final s = await widget.mopidy.getStatus();
    if (!mounted) return;
    setState(() { online = s.online; now = s.nowPlaying ?? '-'; });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bg = online ? Colors.green.shade800 : Colors.red.shade800;
    final icon = online ? Icons.cloud_done : Icons.cloud_off;
    final text = online ? 'ONLINE' : 'OFFLINE';
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 24),
          const Icon(Icons.music_note, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Now Playing: $now', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
