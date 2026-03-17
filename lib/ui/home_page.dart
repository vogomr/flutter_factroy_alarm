import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/mopidy_api.dart';
import 'manual/tornado_alarm_page.dart';
import 'schedules_page.dart';
import 'widgets/alarm_tile.dart';
import 'widgets/grid_painter.dart';
import 'widgets/lcd_display.dart';
import 'widgets/alarm_icon_badge.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }

class _HomePageState extends State<HomePage> {
  final mopidy = MopidyAPI();
  bool busy = false;
  bool systemLive = false;
  String? activeAlarm;
  Timer? _healthTimer;

  @override
  void initState() {
    super.initState();
    _checkHealth();
    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkHealth());
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    try {
      final res = await http.get(Uri.parse('/health')).timeout(const Duration(seconds: 5));
      if (mounted) setState(() => systemLive = res.statusCode == 200);
    } catch (_) {
      if (mounted) setState(() => systemLive = false);
    }
  }

  Future<void> _play(String file, String alarmType) async {
    if (!mounted) return;
    setState(() => busy = true);
    try {
      await mopidy.playTone(file);
      setState(() => activeAlarm = alarmType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing: $file')));
      // Reset active alarm after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => activeAlarm = null);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Play failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrowTopBar = MediaQuery.of(context).size.width < 760;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 5))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // Alarm icon badge
                  const AlarmIconBadge(size: 60, animated: false),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Alarm Controller',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!isNarrowTopBar)
                          Text(
                            'Factory Systems Pro',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: systemLive ? Colors.green : Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: (systemLive ? Colors.green : Colors.red).withValues(alpha: 0.45),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isNarrowTopBar)
                        Text(
                          systemLive ? 'System Live' : 'System Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: systemLive ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      const SizedBox(width: 12),
                      isNarrowTopBar
                          ? IconButton(
                              tooltip: 'Logout',
                              onPressed: _logout,
                              icon: const Icon(Icons.logout_rounded, color: Color(0xFF374151)),
                            )
                          : OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Logout'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          final crossAxisCount = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 1200 ? 3 : 4);
          return Stack(
            children: [
              // Background gradient + subtle texture
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFFEFF3F8), const Color(0xFFF9FBFE)],
                    ),
                  ),
                  child: CustomPaint(
                    painter: GridPainter(),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(children: [
                    Expanded(child: Padding(
                      padding: EdgeInsets.fromLTRB(isSmall ? 16 : 20, 16, isSmall ? 16 : 20, 12),
                      child: Column(
                        children: [
                          // Monitor panel
                          SizedBox(
                            width: double.infinity,
                            child: LcdDisplay(
                              text: activeAlarm != null ? 'ALERT ACTIVE\n${activeAlarm!.toUpperCase()}' : 'SYSTEM_READY',
                              isActive: activeAlarm != null,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Alarm buttons
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                const tiles = [
                                  {'label': 'Lunch Bell', 'icon': Icons.notifications, 'color': Colors.amber, 'file': 'lunch_bell.wav', 'type': 'LUNCH'},
                                  {'label': 'Shift Change', 'icon': Icons.refresh, 'color': Colors.blue, 'file': 'shift_change.wav', 'type': 'SHIFT'},
                                  {'label': 'Emergency Alarm', 'icon': Icons.bolt, 'color': Colors.green, 'file': 'energy_alarm.wav', 'type': 'ENERGY'},
                                  {'label': 'Tornado', 'icon': Icons.warning, 'color': Colors.red, 'file': null, 'type': 'TORNADO'},
                                ];
                                final tile = tiles[index];
                                return AlarmTile(
                                  label: tile['label'] as String,
                                  icon: tile['icon'] as IconData,
                                  color: tile['color'] as Color,
                                  isActive: activeAlarm == tile['type'],
                                  onTap: tile['file'] != null
                                      ? () async {
                                          await _play(tile['file'] as String, tile['type'] as String);
                                        }
                                      : () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const TornadoAlarmPage()),
                                          );
                                        },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footer bar
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: isSmall ? double.infinity : (constraints.maxWidth / 2 - 24),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulesPage())),
                                  icon: const Icon(Icons.schedule, size: 18),
                                  label: const Text('Schedule Setting'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    side: const BorderSide(color: Colors.black12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: isSmall ? double.infinity : (constraints.maxWidth / 2 - 24),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TornadoAlarmPage())),
                                  icon: const Icon(Icons.warning, size: 18),
                                  label: const Text('Manual Tornado'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                    if (busy) const LinearProgressIndicator(minHeight: 4),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
