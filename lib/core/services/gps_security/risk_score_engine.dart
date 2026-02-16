/// Layer 10 & 14: Weighted risk scoring and action determination.
///
/// Collects all [DetectionResult]s from the various checkers and combines
/// them into a single [SecurityState] with a risk level, recommended
/// action, and user-facing messages.
///
/// Scoring table:
/// | Detection              | Score | Critical |
/// |------------------------|-------|----------|
/// | Developer mode         | 100   | Yes      |
/// | Fake GPS app           | 100   | Yes      |
/// | Mock location flag     | 50    | No       |
/// | Teleportation          | 40    | No       |
/// | Accuracy > 50% radius  | 30    | No       |
/// | Sample too perfect     | 25    | No       |
/// | Timestamp drift        | 25    | No       |
/// | Speed mismatch         | 20    | No       |
/// | Accuracy > 30% radius  | 15    | No       |
/// | Sample too noisy       | 15    | No       |
///
/// Risk levels → actions:
/// | 0–20   | LOW      | ALLOW  |
/// | 21–40  | MEDIUM   | ALLOW  |
/// | 41–60  | HIGH     | VERIFY |
/// | 61+    | CRITICAL | BLOCK  |

import 'models.dart';

class RiskScoreEngine {
  RiskScoreEngine._();

  /// Evaluate all inputs and produce a [SecurityState].
  static SecurityState evaluate({
    required List<DetectionResult> detections,
    required bool isInRadius,
    required double? distanceToProject,
    required SamplingResult? samplingResult,
    required DeviceFingerprint? deviceFingerprint,
    required double projectRadius,
    required double? gpsAccuracy,
  }) {
    final allDetections = List<DetectionResult>.from(detections);

    // ----- Adaptive accuracy (Layer 14) -----
    final accuracyResult = _evaluateAccuracy(gpsAccuracy, projectRadius);
    if (accuracyResult != null) allDetections.add(accuracyResult);

    // ----- Multi-sample jitter -----
    if (samplingResult != null) {
      final jitterResult = _evaluateJitter(samplingResult);
      if (jitterResult != null) allDetections.add(jitterResult);
    }

    // ----- Aggregate score -----
    int totalScore = 0;
    bool hasCritical = false;
    for (final d in allDetections) {
      totalScore += d.score;
      if (d.isCritical) hasCritical = true;
    }

    // Determine risk level
    final RiskLevel riskLevel;
    if (hasCritical || totalScore >= 61) {
      riskLevel = RiskLevel.critical;
    } else if (totalScore >= 41) {
      riskLevel = RiskLevel.high;
    } else if (totalScore >= 21) {
      riskLevel = RiskLevel.medium;
    } else {
      riskLevel = RiskLevel.low;
    }

    // Determine action
    final SecurityAction action;
    switch (riskLevel) {
      case RiskLevel.critical:
        action = SecurityAction.block;
      case RiskLevel.high:
        action = SecurityAction.verify;
      case RiskLevel.medium:
      case RiskLevel.low:
        action = SecurityAction.allow;
    }

    // Build messages
    String? primaryMessage;
    final warnings = <String>[];

    if (action == SecurityAction.block) {
      // Use the first critical detection's message, or generic.
      final critical = allDetections.where((d) => d.isCritical);
      primaryMessage = critical.isNotEmpty
          ? critical.first.message
          : 'Terdeteksi aktivitas mencurigakan. Presensi diblokir.';
    }

    for (final d in allDetections) {
      if (!d.isCritical) warnings.add(d.message);
    }

    return SecurityState(
      riskLevel: riskLevel,
      action: action,
      totalScore: totalScore,
      detections: allDetections,
      isInRadius: isInRadius,
      distanceToProject: distanceToProject,
      samplingResult: samplingResult,
      deviceFingerprint: deviceFingerprint,
      primaryMessage: primaryMessage,
      warningMessages: warnings,
      isReady: true,
    );
  }

  // ------------------------------------------------------------------
  // Private evaluators
  // ------------------------------------------------------------------

  /// Adaptive accuracy tolerance (Layer 14).
  static DetectionResult? _evaluateAccuracy(
    double? accuracy,
    double projectRadius,
  ) {
    if (accuracy == null || projectRadius <= 0) return null;
    final ratio = accuracy / projectRadius;
    if (ratio > 0.5) {
      return const DetectionResult(
        type: 'accuracyHigh',
        score: 30,
        message: 'Akurasi GPS terlalu rendah untuk radius lokasi.',
      );
    }
    if (ratio > 0.3) {
      return const DetectionResult(
        type: 'accuracyMedium',
        score: 15,
        message: 'Akurasi GPS kurang optimal.',
      );
    }
    return null;
  }

  /// Multi-sample jitter evaluation.
  static DetectionResult? _evaluateJitter(SamplingResult sampling) {
    if (sampling.jitterStdDev < 0.3) {
      return const DetectionResult(
        type: 'sampleTooPerfect',
        score: 25,
        message: 'Variasi GPS antar-sample terlalu kecil (mencurigakan).',
      );
    }
    if (sampling.jitterStdDev > 50) {
      return const DetectionResult(
        type: 'sampleTooNoisy',
        score: 15,
        message: 'Variasi GPS antar-sample terlalu besar.',
      );
    }
    return null;
  }
}
