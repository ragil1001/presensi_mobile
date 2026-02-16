/// Layer 4: Movement consistency cross-validation.
///
/// Keeps a rolling history of GPS positions and detects:
/// - Teleportation (calculated speed > 100 m/s)
/// - Speed mismatch (reported vs calculated differ > 50 %)
/// - Timestamp drift with large displacement

import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'models.dart';

class MovementAnalyzer {
  static const int maxHistory = 10;

  final List<MovementRecord> _history = [];

  void addRecord(Position position) {
    _history.add(MovementRecord(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: DateTime.now(),
    ));
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }
  }

  /// Analyze the latest movement against history.
  List<DetectionResult> analyze() {
    if (_history.length < 2) return [];

    final results = <DetectionResult>[];
    final prev = _history[_history.length - 2];
    final curr = _history.last;

    final distanceM = _haversineMeters(
      prev.latitude,
      prev.longitude,
      curr.latitude,
      curr.longitude,
    );
    final dtSeconds =
        curr.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;

    if (dtSeconds <= 0) return results;

    final calcSpeed = distanceM / dtSeconds; // m/s

    // 1. Teleportation: calculated speed > 100 m/s
    if (calcSpeed > 100) {
      results.add(DetectionResult(
        type: 'teleportation',
        score: 40,
        message: 'Perpindahan lokasi tidak wajar '
            '(${calcSpeed.toStringAsFixed(1)} m/s).',
      ));
    }

    // 2. Speed mismatch: reported vs calculated differ > 50 %
    if (curr.speed > 0 && calcSpeed > 1) {
      final ratio = (curr.speed - calcSpeed).abs() / calcSpeed;
      if (ratio > 0.5) {
        results.add(const DetectionResult(
          type: 'speedMismatch',
          score: 20,
          message: 'Kecepatan GPS tidak konsisten dengan perpindahan.',
        ));
      }
    }

    // 3. Timestamp drift: big gap (>30 s) + large distance
    if (dtSeconds > 30 && distanceM > 500) {
      results.add(const DetectionResult(
        type: 'timestampDrift',
        score: 25,
        message: 'Perubahan lokasi besar dalam jeda waktu lama.',
      ));
    }

    return results;
  }

  void reset() => _history.clear();

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * pi / 180;
}
