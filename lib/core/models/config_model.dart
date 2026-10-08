class SpotConfig {
  final double spotLength; // meters, default: 4.0
  final double spotWidth; // meters, default: 1.87
  final int idleGapMinutes; // threshold gap in minutes to separate active work shifts, default: 20
  final double targetSpeedSpotsPerHour; // KPI target, default: 200.0
  final double targetDepth; // meters, default: 0.8 (legacy compatibility)
  final double targetDepthCm; // cm, default: 70.0 for crumbling
  final double maxTrenchWidthCm; // cm, default: 110.0
  final double depthTolerancePercent; // %, default: 10.0 (±10%)
  final String themeMode; // 'dark' | 'light'

  const SpotConfig({
    this.spotLength = 4.0,
    this.spotWidth = 1.87,
    this.idleGapMinutes = 20,
    this.targetSpeedSpotsPerHour = 200.0,
    this.targetDepth = 0.8,
    this.targetDepthCm = 70.0,
    this.maxTrenchWidthCm = 110.0,
    this.depthTolerancePercent = 10.0,
    this.themeMode = 'dark',
  });

  /// Single spot footprint area in square meters (m²)
  double get spotAreaM2 => spotLength * spotWidth;

  /// Single spot footprint area in Hectares (Ha) -> 1 Ha = 10,000 m²
  double get spotAreaHa => spotAreaM2 / 10000.0;

  /// Minimum allowable depth (cm) based on tolerance (e.g. -10%)
  double get minAllowedDepthCm => targetDepthCm * (1.0 - (depthTolerancePercent / 100.0));

  /// Maximum allowable depth (cm) based on tolerance (e.g. +10%)
  double get maxAllowedDepthCm => targetDepthCm * (1.0 + (depthTolerancePercent / 100.0));

  SpotConfig copyWith({
    double? spotLength,
    double? spotWidth,
    int? idleGapMinutes,
    double? targetSpeedSpotsPerHour,
    double? targetDepth,
    double? targetDepthCm,
    double? maxTrenchWidthCm,
    double? depthTolerancePercent,
    String? themeMode,
  }) {
    return SpotConfig(
      spotLength: spotLength ?? this.spotLength,
      spotWidth: spotWidth ?? this.spotWidth,
      idleGapMinutes: idleGapMinutes ?? this.idleGapMinutes,
      targetSpeedSpotsPerHour: targetSpeedSpotsPerHour ?? this.targetSpeedSpotsPerHour,
      targetDepth: targetDepth ?? this.targetDepth,
      targetDepthCm: targetDepthCm ?? this.targetDepthCm,
      maxTrenchWidthCm: maxTrenchWidthCm ?? this.maxTrenchWidthCm,
      depthTolerancePercent: depthTolerancePercent ?? this.depthTolerancePercent,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'spotLength': spotLength,
      'spotWidth': spotWidth,
      'idleGapMinutes': idleGapMinutes,
      'targetSpeedSpotsPerHour': targetSpeedSpotsPerHour,
      'targetDepth': targetDepth,
      'targetDepthCm': targetDepthCm,
      'maxTrenchWidthCm': maxTrenchWidthCm,
      'depthTolerancePercent': depthTolerancePercent,
      'themeMode': themeMode,
    };
  }

  factory SpotConfig.fromMap(Map<String, dynamic> map) {
    final legacyDepth = (map['targetDepth'] as num?)?.toDouble() ?? 0.8;
    final depthCm = (map['targetDepthCm'] as num?)?.toDouble() ??
        (map.containsKey('targetDepth') ? legacyDepth * 100.0 : 70.0);

    return SpotConfig(
      spotLength: (map['spotLength'] as num?)?.toDouble() ?? 4.0,
      spotWidth: (map['spotWidth'] as num?)?.toDouble() ?? 1.87,
      idleGapMinutes: (map['idleGapMinutes'] as num?)?.toInt() ?? 20,
      targetSpeedSpotsPerHour: (map['targetSpeedSpotsPerHour'] as num?)?.toDouble() ?? 200.0,
      targetDepth: legacyDepth,
      targetDepthCm: depthCm,
      maxTrenchWidthCm: (map['maxTrenchWidthCm'] as num?)?.toDouble() ?? 110.0,
      depthTolerancePercent: (map['depthTolerancePercent'] as num?)?.toDouble() ?? 10.0,
      themeMode: map['themeMode']?.toString() ?? 'dark',
    );
  }
}
