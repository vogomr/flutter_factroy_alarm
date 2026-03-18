import 'package:flutter/foundation.dart';

// lib/config.dart
//
// OPTION B: Same-origin proxy on the Raspberry Pi
// -----------------------------------------------
// Your Flutter Web UI is served from:   http://<PI-IP>/
// Mopidy API is proxied via Nginx at:   http://<PI-IP>/mopidy/rpc
//
// Because both share the same host + port (same-origin),
// we set the base URL to an empty string so MopidyAPI
// builds URLs like:
//
//     /mopidy/rpc
//
// which Nginx will forward to Mopidy on localhost:6680.

class AppConfig {
  // Web: same-origin through Nginx. Mobile/Desktop: direct to server IP.
  static const String mopidyBaseUrl = kIsWeb ? '' : 'http://10.1.98.26';

  // Web: same-origin through Nginx. Mobile/Desktop: direct to server IP.
  static const String scheduleBaseUrl = kIsWeb ? '' : 'http://10.1.98.26';

  // Web uses the nginx proxy path, mobile hits the Python server directly.
  static const String healthUrl =
      kIsWeb ? '/health/schedule' : 'http://10.1.98.26/health';

  // Mopidy media_dir on the server where alarm tones are stored.
  static const String mopidyMediaDir = '/var/lib/mopidy/media';
}