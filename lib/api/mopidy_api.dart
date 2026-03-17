import 'dart:async';
import 'dart:convert';

import '../config.dart'; // <-- make sure this exists and has AppConfig.mopidyBaseUrl
import 'mopidy_rpc_transport_stub.dart'
  if (dart.library.html) 'mopidy_rpc_transport_web.dart' as rpc_transport;

/// Mopidy JSON-RPC helper.
/// Option B (same-origin through Nginx): set AppConfig.mopidyBaseUrl = '' so calls go to /mopidy/rpc
/// Option 1 (direct-to-Mopidy during local dev): set AppConfig.mopidyBaseUrl = 'http://<PI-IP>:6680'
class MopidyStatus {
  final bool online;
  final String? nowPlaying;
  MopidyStatus({required this.online, this.nowPlaying});
}

class MopidyAPI {
  /// Normal usage: MopidyAPI() will use AppConfig.mopidyBaseUrl
  /// You can still override: MopidyAPI(base: 'http://192.168.1.25:6680')
  final String base;
  MopidyAPI({String? base})
      : base = (base ?? AppConfig.mopidyBaseUrl).replaceAll(RegExp(r'/$'), '');

  Uri _rpcUri() => Uri.parse('$base/mopidy/rpc');

  void _throwIfRpcError(dynamic json) {
    if (json is Map<String, dynamic> && json['error'] != null) {
      throw Exception('Mopidy RPC error: ${json['error']}');
    }
  }

  Future<void> _rpc(String method, {Map<String, dynamic>? params}) async {
    final payload = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': method,
      if (params != null) 'params': params,
    };
    final response = await rpc_transport.postJson(_rpcUri(), payload);
    if (response.statusCode != 200) {
      throw Exception('Mopidy RPC failed: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body);
    _throwIfRpcError(json);
  }

  /// Helper that returns the parsed JSON `result` field.
  Future<dynamic> _rpcResult(String method, {Map<String, dynamic>? params}) async {
    final payload = {
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': method,
      if (params != null) 'params': params,
    };
    final response = await rpc_transport.postJson(_rpcUri(), payload);
    if (response.statusCode != 200) {
      throw Exception('Mopidy RPC failed: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body);
    _throwIfRpcError(json);
    return json['result'];
  }

  Future<void> clear() async => _rpc('core.tracklist.clear');
  Future<void> add(String uri) async => _rpc('core.tracklist.add', params: {'uris': [uri]});
  Future<void> play() async => _rpc('core.playback.play');
  Future<void> stop() async => _rpc('core.playback.stop');

  /// Software mixer volume 0..100
  Future<void> setVolume(int volume) =>
      _rpc('core.mixer.set_volume', params: {'volume': volume.clamp(0, 100)});

  /// Repeat on/off (loops current tracklist)
  Future<void> setRepeat(bool value) =>
      _rpc('core.tracklist.set_repeat', params: {'value': value});

  /// Convenience: play a local file (by filename under media_dir)
  Future<void> playTone(String filename, {int? volume}) async {
    final uri = Uri.file('${AppConfig.mopidyMediaDir}/$filename').toString();
    if (volume != null) await setVolume(volume);
    await clear();
    await add(uri);
    await play();
  }

  /// Play a file, then auto-stop after N seconds (non-blocking).
  Future<void> playToneFor(String filename, {int? volume, int seconds = 20}) async {
    await playTone(filename, volume: volume);
    unawaited(Future.delayed(Duration(seconds: seconds), () => stop()));
  }

  /// Lightweight "ping" + optional now-playing.
  Future<MopidyStatus> getStatus() async {
    try {
      final result = await _rpcResult('core.playback.get_current_tl_track');
      if (result == null) return MopidyStatus(online: true);
      final track = result['track'];
      final title = track != null ? (track['name'] ?? track['uri'] as String?) : null;
      return MopidyStatus(online: true, nowPlaying: title);
    } catch (_) {
      return MopidyStatus(online: false);
    }
  }

  /// Simple ping by asking for the server version. Throws on failure.
  Future<void> ping() => _rpc('core.get_version');
}