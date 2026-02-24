/// Orchestrator: coordinates all GPS security services.
///
/// `AbsensiPage` only interacts with this class. On every GPS stream
/// update, call [processPosition] which runs all detectors, feeds
/// the results into the [RiskScoreEngine], and notifies via
/// [onStateChanged].
///
/// When submitting presensi, call [buildPayload] to get a signed
/// [SecurityPayload] for the server.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'fake_gps_detector.dart';
import 'device_integrity_checker.dart';
import 'location_sampler.dart';
import 'movement_analyzer.dart';
import 'risk_score_engine.dart';

class SecurityManager {
  final LocationSampler _sampler = LocationSampler();
  final MovementAnalyzer _movementAnalyzer = MovementAnalyzer();

  double? _projectLat;
  double? _projectLng;
  double? _projectRadius;

  SecurityState _state = SecurityState.initial();
  DeviceFingerprint? _deviceFingerprint;
  bool _initialChecksComplete = false;

  /// Once true, SecurityManager will never unblock until reset().
  bool _permanentlyBlocked = false;

  Position? _lastPosition;

  /// Callback invoked whenever the security state changes.
  final void Function(SecurityState) onStateChanged;

  SecurityManager({required this.onStateChanged});

  SecurityState get state => _state;

  /// Configure with project coordinates (from cek-presensi response).
  void configure({
    required double projectLat,
    required double projectLng,
    required double projectRadius,
  }) {
    _projectLat = projectLat;
    _projectLng = projectLng;
    _projectRadius = projectRadius;
  }

  /// Process an incoming GPS position. Should be called on every
  /// location stream update.
  Future<void> processPosition(Position position) async {
    _lastPosition = position;

    // ── Permanent block: once triggered, never lift until reset() ──
    // Re-emit the existing blocked state so UI stays in sync.
    if (_permanentlyBlocked) {
      onStateChanged(_state);
      return;
    }

    // Feed into sub-services.
    _sampler.addSample(position);
    _movementAnalyzer.addRecord(position);

    // Calculate distance to project.
    double? distance;
    bool isInRadius = false;
    if (_projectLat != null && _projectLng != null && _projectRadius != null) {
      distance = _haversineMeters(
        position.latitude,
        position.longitude,
        _projectLat!,
        _projectLng!,
      );
      isInRadius = distance <= _projectRadius!;
    }

    // ------ Collect all detections ------
    final detections = <DetectionResult>[];

    // One-time full check (fake GPS apps, developer mode, mock flag)
    if (!_initialChecksComplete) {
      try {
        final fakeGpsResults = await FakeGpsDetector.runAllChecks(position);
        detections.addAll(fakeGpsResults);

        _deviceFingerprint = await DeviceIntegrityChecker.collectFingerprint();

        _initialChecksComplete = true;
      } catch (e) {
        debugPrint('SecurityManager initial checks error: $e');
        _initialChecksComplete = true;
      }
    } else {
      // On every subsequent update: re-check developer mode (user can enable
      // it after the app opens) AND the mock location flag.
      try {
        final devMode = await FakeGpsDetector.checkDeveloperMode();
        if (devMode != null) detections.add(devMode);
      } catch (e) {
        debugPrint('SecurityManager devMode re-check error: $e');
      }
      final mock = FakeGpsDetector.checkMockLocation(position);
      if (mock != null) detections.add(mock);
    }

    // Movement analysis
    detections.addAll(_movementAnalyzer.analyze());

    // ------ Score everything ------
    _state = RiskScoreEngine.evaluate(
      detections: detections,
      isInRadius: isInRadius,
      distanceToProject: distance,
      samplingResult: _sampler.analyze(),
      deviceFingerprint: _deviceFingerprint,
      projectRadius: _projectRadius ?? 300,
      gpsAccuracy: position.accuracy,
    );

    // Lock permanently once a block decision is made.
    if (_state.action == SecurityAction.block) {
      _permanentlyBlocked = true;
      debugPrint('🔒 SecurityManager: PERMANENTLY BLOCKED — fake GPS detected.');
    }

    onStateChanged(_state);
  }

  /// Build a signed [SecurityPayload] for server submission.
  SecurityPayload buildPayload({
    required String presensiToken,
    required String deviceId,
    required String jenis,
    required int jadwalId,
    required double latitude,
    required double longitude,
    int? selfieTimestampMs,
  }) {
    final nonce = const Uuid().v4();
    final timestampMs = DateTime.now().millisecondsSinceEpoch;

    // HMAC-SHA256 anti-tampering (Layer 11)
    final signString =
        '$presensiToken|$jenis|$jadwalId|$latitude|$longitude|$timestampMs|$nonce';
    final keyBytes =
        sha256.convert(utf8.encode('$presensiToken$deviceId')).bytes;
    final hmacSignature =
        Hmac(sha256, keyBytes).convert(utf8.encode(signString)).toString();

    return SecurityPayload(
      presensiToken: presensiToken,
      nonce: nonce,
      hmacSignature: hmacSignature,
      timestampMs: timestampMs,
      gpsAccuracy: _lastPosition?.accuracy,
      gpsSpeed: _lastPosition?.speed,
      isMockLocation: _lastPosition?.isMocked ?? false,
      sampleCount: _sampler.sampleCount,
      sampleJitterStdDev: _sampler.analyze()?.jitterStdDev,
      clientRiskScore: _state.totalScore,
      clientRiskLevel: _state.riskLevel.name.toUpperCase(),
      riskFactors: _state.detections.map((d) => d.type).toList(),
      device: _deviceFingerprint ??
          DeviceFingerprint(
            deviceId: deviceId,
            deviceModel: '',
            deviceBrand: '',
            osVersion: '',
          ),
      selfieTimestampMs: selfieTimestampMs,
    );
  }

  void reset() {
    _sampler.reset();
    _movementAnalyzer.reset();
    _state = SecurityState.initial();
    _initialChecksComplete = false;
    _permanentlyBlocked = false;
    _deviceFingerprint = null;
    _lastPosition = null;
  }

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
