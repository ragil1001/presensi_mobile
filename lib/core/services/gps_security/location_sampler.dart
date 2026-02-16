/// Layer 5: Multi-sample GPS validation with jitter analysis.
///
/// Collects [requiredSamples] GPS readings, then computes the median
/// position and standard deviation (in meters) between samples.
///
/// - stdDev < 0.3 m → suspiciously perfect (static fake GPS)
/// - stdDev > 50 m  → too noisy (manipulation or broken GPS)
/// - 0.3–50 m       → normal GPS jitter

import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'models.dart';

class LocationSampler {
  static const int requiredSamples = 5;

  final List<LocationSample> _samples = [];

  void addSample(Position position) {
    _samples.add(LocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
      isMocked: position.isMocked,
    ));
  }

  bool get isComplete => _samples.length >= requiredSamples;
  int get sampleCount => _samples.length;

  /// Analyze collected samples. Returns `null` if not enough data yet.
  SamplingResult? analyze() {
    if (_samples.length < 2) return null;

    final medianLat = _median(_samples.map((s) => s.latitude).toList());
    final medianLng = _median(_samples.map((s) => s.longitude).toList());

    // Calculate distances from each sample to the median point.
    final distances = _samples.map((s) {
      return _haversineMeters(s.latitude, s.longitude, medianLat, medianLng);
    }).toList();

    final mean = distances.reduce((a, b) => a + b) / distances.length;
    final variance =
        distances.map((d) => (d - mean) * (d - mean)).reduce((a, b) => a + b) /
            distances.length;
    final stdDev = sqrt(variance);

    final suspicious = stdDev < 0.3 || stdDev > 50;

    return SamplingResult(
      medianLat: medianLat,
      medianLng: medianLng,
      jitterStdDev: stdDev,
      sampleCount: _samples.length,
      isSuspicious: suspicious,
    );
  }

  void reset() => _samples.clear();

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  static double _median(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Haversine distance in meters between two lat/lng points.
  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
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
