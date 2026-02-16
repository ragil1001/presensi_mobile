/// Layer 6: Device fingerprint collection.
///
/// Collects hardware identifiers for the security payload.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:safe_device/safe_device.dart';

import 'models.dart';

class DeviceIntegrityChecker {
  DeviceIntegrityChecker._();

  static const _emulatorHints = [
    'sdk',
    'emulator',
    'genymotion',
    'generic',
    'goldfish',
    'ranchu',
    'google_sdk',
    'sdk_gphone',
    'vbox',
  ];

  /// Collect a full [DeviceFingerprint] from the current device.
  static Future<DeviceFingerprint> collectFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceModel = '';
    String deviceBrand = '';
    String osVersion = '';
    bool isEmulator = false;

    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        deviceId = android.id;
        deviceModel = android.model;
        deviceBrand = android.brand;
        osVersion = 'Android ${android.version.release}';
        isEmulator = !android.isPhysicalDevice ||
            _matchesEmulatorHint(android.model) ||
            _matchesEmulatorHint(android.product) ||
            _matchesEmulatorHint(android.hardware);
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        deviceId = ios.identifierForVendor ?? '';
        deviceModel = ios.utsname.machine;
        deviceBrand = 'Apple';
        osVersion = 'iOS ${ios.systemVersion}';
        isEmulator = !ios.isPhysicalDevice;
      }
    } catch (e) {
      debugPrint('DeviceIntegrityChecker.collectFingerprint error: $e');
    }

    bool isRealDevice = true;
    bool isDeveloperMode = false;
    try {
      isRealDevice = await SafeDevice.isRealDevice;
      if (Platform.isAndroid) {
        isDeveloperMode = await SafeDevice.isDevelopmentModeEnable;
      }
    } catch (e) {
      debugPrint('DeviceIntegrityChecker SafeDevice error: $e');
    }

    return DeviceFingerprint(
      deviceId: deviceId,
      deviceModel: deviceModel,
      deviceBrand: deviceBrand,
      osVersion: osVersion,
      isEmulator: isEmulator,
      isRealDevice: isRealDevice,
      isDeveloperMode: isDeveloperMode,
    );
  }

  static bool _matchesEmulatorHint(String value) {
    final lower = value.toLowerCase();
    return _emulatorHints.any((hint) => lower.contains(hint));
  }
}
