import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String PRIMARY_BACKEND_HOST = '192.168.100.58';
const String FALLBACK_BACKEND_HOST = '192.168.1.76';
const String OLD_BACKEND_HOST = '192.168.100.55';

// List of available hosts in order of priority
const List<String> BACKEND_HOSTS = [
  PRIMARY_BACKEND_HOST,
  FALLBACK_BACKEND_HOST,
];

// All historical IPs that might be in the database
const List<String> ALL_HISTORICAL_HOSTS = [
  PRIMARY_BACKEND_HOST,
  FALLBACK_BACKEND_HOST,
  OLD_BACKEND_HOST,
  '127.0.0.1',
  'localhost',
];

int _currentHostIndex = 0;

String get BACKEND_HOST => BACKEND_HOSTS[_currentHostIndex];

/// Probes available hosts and sets the first reachable one as current.
Future<void> initHosts() async {
  if (kIsWeb) return;
  
  for (int i = 0; i < BACKEND_HOSTS.length; i++) {
    try {
      final response = await http.get(Uri.parse('http://${BACKEND_HOSTS[i]}:8000/')).timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        _currentHostIndex = i;
        debugPrint('Connected to backend host: ${BACKEND_HOSTS[i]}');
        return;
      }
    } catch (_) {
      // Continue to next host
    }
  }
  debugPrint('Warning: No backend host reachable. Defaulting to primary.');
}

/// Switches to the next available host in the list.
/// Returns the new host.
String switchToNextHost() {
  _currentHostIndex = (_currentHostIndex + 1) % BACKEND_HOSTS.length;
  return BACKEND_HOST;
}

/// Resets to the primary host.
void resetToPrimaryHost() {
  _currentHostIndex = 0;
}

/// Replaces any known backend host IP in the given URL with the currently active one.
String fixEmulatorUrl(String? url) {
  if (url == null || url.isEmpty) return url ?? '';
  
  String fixedUrl = url;
  for (final host in ALL_HISTORICAL_HOSTS) {
    if (fixedUrl.contains(host)) {
      // Avoid replacing localhost if we are on web
      if (kIsWeb && (host == 'localhost' || host == '127.0.0.1')) continue;
      
      fixedUrl = fixedUrl.replaceAll(host, BACKEND_HOST);
    }
  }
  return fixedUrl;
}

String getBackendUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  }
  return 'http://$BACKEND_HOST:8000';
}

String getEmulatorHost() {
  if (kIsWeb) {
    return 'localhost';
  }
  return BACKEND_HOST;
}
