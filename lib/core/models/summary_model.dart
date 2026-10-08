import 'spot_model.dart';

class OperatorProductivity {
  final String operatorId;
  final int spotsCount;
  final double areaHa;
  final double activeHours;
  final double spotsPerHour;
  final double metersDone;
  final double metersPerHour;

  const OperatorProductivity({
    required this.operatorId,
    required this.spotsCount,
    required this.areaHa,
    required this.activeHours,
    required this.spotsPerHour,
    this.metersDone = 0.0,
    this.metersPerHour = 0.0,
  });
}

class DailyProductivity {
  final String date;
  final int spotsDone;
  final double areaHa;
  final double activeHours;
  final double spotsPerHour;
  final double metersDone;
  final double metersPerHour;
  final double? avgDepthCm;
  final double? avgDeviationCm;

  const DailyProductivity({
    required this.date,
    required this.spotsDone,
    required this.areaHa,
    required this.activeHours,
    required this.spotsPerHour,
    this.metersDone = 0.0,
    this.metersPerHour = 0.0,
    this.avgDepthCm,
    this.avgDeviationCm,
  });
}

class SpotSummary {
  final int totalSpots;
  final int doneSpots;
  final int pendingSpots;
  final int inProgressSpots;
  final int otherSpots;
  final double completionRate; // 0 - 100 %

  // Mode Crumbling Identifiers & Length
  final bool isCrumbling;
  final double totalLengthMeters;
  final double doneLengthMeters;
  final double inProgressLengthMeters;
  final double speedMetersPerHour;
  final double avgDeviationCm;
  final double avgTrenchWidthCm;
  final Map<CrumblingQCStatus, int> qcDistribution;

  // Footprint Calculations
  final double spotFootprintM2; // spotLength * spotWidth
  final double totalAreaM2; // Footprint area in m²
  final double totalAreaHa; // totalAreaM2 / 10000.0

  // Time & Speed Calculations
  final double activeWorkHours; // continuous digging time with gap < idleGapMinutes
  final double grossWorkHours; // maxTimestamp - minTimestamp
  final double idleHours; // grossWorkHours - activeWorkHours
  final double speedSpotsPerHour; // doneSpots / activeWorkHours
  final double speedHaPerHour; // totalAreaHa / activeWorkHours
  final double avgSecondsPerSpot; // activeWorkHours * 3600 / doneSpots

  final DateTime? minTimestamp;
  final DateTime? maxTimestamp;

  // Breakdown statistics
  final List<DailyProductivity> dailyBreakdown;
  final List<OperatorProductivity> operatorBreakdown;
  final Map<String, int> equipmentCounts;
  final double averageAccuracy;
  final double averageDepth;

  const SpotSummary({
    required this.totalSpots,
    required this.doneSpots,
    required this.pendingSpots,
    this.inProgressSpots = 0,
    required this.otherSpots,
    required this.completionRate,
    this.isCrumbling = false,
    this.totalLengthMeters = 0.0,
    this.doneLengthMeters = 0.0,
    this.inProgressLengthMeters = 0.0,
    this.speedMetersPerHour = 0.0,
    this.avgDeviationCm = 0.0,
    this.avgTrenchWidthCm = 0.0,
    this.qcDistribution = const {},
    required this.spotFootprintM2,
    required this.totalAreaM2,
    required this.totalAreaHa,
    required this.activeWorkHours,
    required this.grossWorkHours,
    required this.idleHours,
    required this.speedSpotsPerHour,
    required this.speedHaPerHour,
    required this.avgSecondsPerSpot,
    this.minTimestamp,
    this.maxTimestamp,
    required this.dailyBreakdown,
    required this.operatorBreakdown,
    required this.equipmentCounts,
    required this.averageAccuracy,
    required this.averageDepth,
  });

  static SpotSummary empty({double spotLength = 4.0, double spotWidth = 1.87}) {
    final footprint = spotLength * spotWidth;
    return SpotSummary(
      totalSpots: 0,
      doneSpots: 0,
      pendingSpots: 0,
      inProgressSpots: 0,
      otherSpots: 0,
      completionRate: 0.0,
      isCrumbling: false,
      totalLengthMeters: 0.0,
      doneLengthMeters: 0.0,
      inProgressLengthMeters: 0.0,
      speedMetersPerHour: 0.0,
      avgDeviationCm: 0.0,
      avgTrenchWidthCm: 0.0,
      qcDistribution: const {},
      spotFootprintM2: footprint,
      totalAreaM2: 0.0,
      totalAreaHa: 0.0,
      activeWorkHours: 0.0,
      grossWorkHours: 0.0,
      idleHours: 0.0,
      speedSpotsPerHour: 0.0,
      speedHaPerHour: 0.0,
      avgSecondsPerSpot: 0.0,
      dailyBreakdown: const [],
      operatorBreakdown: const [],
      equipmentCounts: const {},
      averageAccuracy: 0.0,
      averageDepth: 0.0,
    );
  }
}
