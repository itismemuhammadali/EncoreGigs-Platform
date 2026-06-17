import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

const String PRIMARY_BACKEND_HOST = '192.168.100.55';
const String FALLBACK_BACKEND_HOST = '10.0.2.2'; // Standard Android Emulator loopback
const String OLD_BACKEND_HOST = '192.168.1.76';

// List of available hosts in order of priority
List<String> get BACKEND_HOSTS {
  if (kIsWeb) return ['localhost', '127.0.0.1'];
  if (Platform.isAndroid) {
    return [
      '10.0.2.2', // Android emulator loopback to host
      '127.0.0.1',
      PRIMARY_BACKEND_HOST,
    ];
  }
  // iOS and others
  return [
    '127.0.0.1',
    'localhost',
    PRIMARY_BACKEND_HOST,
    '10.0.2.2',
  ];
}

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
  
  final hosts = BACKEND_HOSTS;
  for (int i = 0; i < hosts.length; i++) {
    try {
      final host = hosts[i];
      // Defensive check: 127.0.0.1 on Android usually refers to the device itself
      // We want to avoid it if 10.0.2.2 is available and we are on an emulator
      if (Platform.isAndroid && host == '127.0.0.1' && hosts.contains('10.0.2.2')) {
        // Only try 127.0.0.1 on Android if 10.0.2.2 was already tried or not present
      }

      final response = await http.get(Uri.parse('http://$host:8000/')).timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        _currentHostIndex = i;
        debugPrint('Connected to backend host: $host');
        return;
      }
    } catch (_) {
      // Continue to next host
    }
  }
  
  // If we couldn't reach any host, fallback to a sensible default for the platform
  if (Platform.isAndroid) {
    for (int i = 0; i < hosts.length; i++) {
      if (hosts[i] == '10.0.2.2') {
        _currentHostIndex = i;
        break;
      }
    }
  }
  debugPrint('Warning: No backend host reachable. Defaulting to: ${BACKEND_HOST}');
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
