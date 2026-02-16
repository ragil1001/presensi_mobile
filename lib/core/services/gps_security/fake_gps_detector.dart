/// Layer 3: Mock location, developer mode, and known fake GPS app detection.
///
/// Static utility class — stateless, all methods are independent checks
/// that return [DetectionResult] when a threat is found.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';
import 'package:installed_apps/installed_apps.dart';

import 'models.dart';

class FakeGpsDetector {
  FakeGpsDetector._();

  /// Known fake GPS / location spoofing packages (Android).
  static const List<String> knownFakeGpsPackages = [
    'com.lexa.fakegps',
    'com.incorporateapps.fakegps.fre',
    'com.fakegps.mock',
    'com.blogspot.newapphorizons.fakegps',
    'com.gsmartstudio.fakegps',
    'com.fakegps.route',
    'com.evezzon.fakegps',
    'com.theappninjas.gpsjoystick',
    'com.theappninjas.fakegpsjoystick',
    'org.hola.gpslocation',
    'com.lkr.fakelocation',
    'com.fake.gps.location',
    'com.rosteam.gpsemulator',
    'fr.dvilleneuve.lockito',
  ];

  // ------------------------------------------------------------------
  // Individual checks
  // ------------------------------------------------------------------

  /// Developer mode enabled — score 100, critical.
  static Future<DetectionResult?> checkDeveloperMode() async {
    if (!Platform.isAndroid) return null;
    try {
      final enabled = await SafeDevice.isDevelopmentModeEnable;
      if (enabled) {
        return const DetectionResult(
          type: 'developerMode',
          score: 100,
          message: 'Mode pengembang (Developer Mode) aktif. '
              'Nonaktifkan untuk melanjutkan presensi.',
          isCritical: true,
        );
      }
    } catch (e) {
      debugPrint('FakeGpsDetector.checkDeveloperMode error: $e');
    }
    return null;
  }

  /// Position.isMocked flag — score 50.
  static DetectionResult? checkMockLocation(Position position) {
    if (position.isMocked) {
      return const DetectionResult(
        type: 'mockLocation',
        score: 50,
        message: 'Terdeteksi lokasi palsu (mock location).',
      );
    }
    return null;
  }

  /// Known fake GPS apps installed — score 100, critical.
  static Future<DetectionResult?> checkFakeGpsApps() async {
    if (!Platform.isAndroid) return null;
    try {
      for (final pkg in knownFakeGpsPackages) {
        final installed = await InstalledApps.isAppInstalled(pkg);
        if (installed ?? false) {
          return DetectionResult(
            type: 'fakeGpsApp',
            score: 100,
            message: 'Terdeteksi aplikasi pemalsu lokasi ($pkg). '
                'Hapus aplikasi tersebut untuk melanjutkan presensi.',
            isCritical: true,
          );
        }
      }
    } catch (e) {
      debugPrint('FakeGpsDetector.checkFakeGpsApps error: $e');
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Convenience: run all checks at once
  // ------------------------------------------------------------------

  /// Returns every [DetectionResult] that fired.
  static Future<List<DetectionResult>> runAllChecks(Position position) async {
    final results = <DetectionResult>[];

    final devMode = await checkDeveloperMode();
    if (devMode != null) results.add(devMode);

    final mock = checkMockLocation(position);
    if (mock != null) results.add(mock);

    final fakeApp = await checkFakeGpsApps();
    if (fakeApp != null) results.add(fakeApp);

    return results;
  }
}
