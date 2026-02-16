/// GPS Security data classes for the 15-layer anti-fake GPS system.
///
/// Provides enums, value objects, and payload structures used across
/// all security services (detector, sampler, analyzer, scorer, manager).

enum RiskLevel { low, medium, high, critical }

enum SecurityAction { allow, verify, block }

class DetectionResult {
  final String type;
  final int score;
  final String message;
  final bool isCritical;

  const DetectionResult({
    required this.type,
    required this.score,
    required this.message,
    this.isCritical = false,
  });
}

class LocationSample {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isMocked;

  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.isMocked = false,
  });
}

class SamplingResult {
  final double medianLat;
  final double medianLng;
  final double jitterStdDev;
  final int sampleCount;
  final bool isSuspicious;

  const SamplingResult({
    required this.medianLat,
    required this.medianLng,
    required this.jitterStdDev,
    required this.sampleCount,
    required this.isSuspicious,
  });
}

class MovementRecord {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const MovementRecord({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });
}

class DeviceFingerprint {
  final String deviceId;
  final String deviceModel;
  final String deviceBrand;
  final String osVersion;
  final bool isEmulator;
  final bool isRealDevice;
  final bool isDeveloperMode;

  const DeviceFingerprint({
    required this.deviceId,
    required this.deviceModel,
    required this.deviceBrand,
    required this.osVersion,
    this.isEmulator = false,
    this.isRealDevice = true,
    this.isDeveloperMode = false,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_model': deviceModel,
        'device_brand': deviceBrand,
        'os_version': osVersion,
        'is_emulator': isEmulator,
        'is_real_device': isRealDevice,
        'is_developer_mode': isDeveloperMode,
      };
}

class SecurityState {
  final RiskLevel riskLevel;
  final SecurityAction action;
  final int totalScore;
  final List<DetectionResult> detections;
  final bool isInRadius;
  final double? distanceToProject;
  final SamplingResult? samplingResult;
  final DeviceFingerprint? deviceFingerprint;
  final String? primaryMessage;
  final List<String> warningMessages;
  final bool isReady;

  const SecurityState({
    required this.riskLevel,
    required this.action,
    required this.totalScore,
    required this.detections,
    required this.isInRadius,
    this.distanceToProject,
    this.samplingResult,
    this.deviceFingerprint,
    this.primaryMessage,
    required this.warningMessages,
    required this.isReady,
  });

  factory SecurityState.initial() => const SecurityState(
        riskLevel: RiskLevel.low,
        action: SecurityAction.allow,
        totalScore: 0,
        detections: [],
        isInRadius: false,
        warningMessages: [],
        isReady: false,
      );

  SecurityState copyWith({
    RiskLevel? riskLevel,
    SecurityAction? action,
    int? totalScore,
    List<DetectionResult>? detections,
    bool? isInRadius,
    double? distanceToProject,
    SamplingResult? samplingResult,
    DeviceFingerprint? deviceFingerprint,
    String? primaryMessage,
    List<String>? warningMessages,
    bool? isReady,
  }) {
    return SecurityState(
      riskLevel: riskLevel ?? this.riskLevel,
      action: action ?? this.action,
      totalScore: totalScore ?? this.totalScore,
      detections: detections ?? this.detections,
      isInRadius: isInRadius ?? this.isInRadius,
      distanceToProject: distanceToProject ?? this.distanceToProject,
      samplingResult: samplingResult ?? this.samplingResult,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      primaryMessage: primaryMessage ?? this.primaryMessage,
      warningMessages: warningMessages ?? this.warningMessages,
      isReady: isReady ?? this.isReady,
    );
  }
}

class SecurityPayload {
  final String presensiToken;
  final String nonce;
  final String hmacSignature;
  final int timestampMs;
  final double? gpsAccuracy;
  final double? gpsSpeed;
  final bool isMockLocation;
  final int sampleCount;
  final double? sampleJitterStdDev;
  final int clientRiskScore;
  final String clientRiskLevel;
  final List<String> riskFactors;
  final DeviceFingerprint device;
  final int? selfieTimestampMs;

  const SecurityPayload({
    required this.presensiToken,
    required this.nonce,
    required this.hmacSignature,
    required this.timestampMs,
    this.gpsAccuracy,
    this.gpsSpeed,
    this.isMockLocation = false,
    this.sampleCount = 0,
    this.sampleJitterStdDev,
    this.clientRiskScore = 0,
    this.clientRiskLevel = 'LOW',
    this.riskFactors = const [],
    required this.device,
    this.selfieTimestampMs,
  });

  /// Flatten to Map<String, dynamic> for FormData submission.
  Map<String, dynamic> toFormFields() => {
        'presensi_token': presensiToken,
        'nonce': nonce,
        'hmac_signature': hmacSignature,
        'timestamp_ms': timestampMs,
        if (gpsAccuracy != null) 'gps_accuracy': gpsAccuracy,
        if (gpsSpeed != null) 'gps_speed': gpsSpeed,
        'is_mock_location': isMockLocation ? '1' : '0',
        'sample_count': sampleCount,
        if (sampleJitterStdDev != null)
          'sample_jitter_stddev': sampleJitterStdDev,
        'client_risk_score': clientRiskScore,
        'client_risk_level': clientRiskLevel,
        'risk_factors': riskFactors.join(','),
        'device_model': device.deviceModel,
        'device_brand': device.deviceBrand,
        'device_os_version': device.osVersion,
        'is_emulator': device.isEmulator ? '1' : '0',
        if (selfieTimestampMs != null)
          'selfie_timestamp_ms': selfieTimestampMs,
      };
}
