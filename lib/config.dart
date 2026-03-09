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
  // Use the same-origin Mopidy proxy provided by Nginx
  static const String mopidyBaseUrl = '';
}