import '../models/config_model.dart';
import '../models/spot_model.dart';
import '../models/summary_model.dart';

class CalculationEngine {
  static SpotSummary calculate({
    required List<Spot> spots,
    required SpotConfig config,
  }) {
    if (spots.isEmpty) {
      return SpotSummary.empty(
        spotLength: config.spotLength,
        spotWidth: config.spotWidth,
      );
    }

    final totalSpots = spots.length;
    final bool isCrumbling = spots.any((s) => s.isLineString);

    int doneCount = 0;
    int pendingCount = 0;
    int inProgressCount = 0;
    int otherCount = 0;

    double totalLengthMeters = 0.0;
    double doneLengthMeters = 0.0;
    double inProgressLengthMeters = 0.0;

    double accuracySum = 0.0;
    int accuracyCount = 0;
    double depthSum = 0.0;
    int depthCount = 0;
    double devSum = 0.0;
    int devCount = 0;
    double widthSum = 0.0;
    int widthCount = 0;

    final Map<CrumblingQCStatus, int> qcDistribution = {};

    final List<Spot> doneSpotsWithTime = [];
    final Map<String, List<Spot>> spotsByDate = {};
    final Map<String, List<Spot>> spotsByOperator = {};
    final Map<String, int> equipmentCounts = {};

    for (final spot in spots) {
      final segLength = spot.lengthMeters ?? 1.0;
      totalLengthMeters += segLength;

      if (spot.isDone) {
        doneCount++;
        doneLengthMeters += segLength;
        if (spot.timestamp != null) {
          doneSpotsWithTime.add(spot);
        }
      } else if (spot.isInProgress) {
        inProgressCount++;
        inProgressLengthMeters += segLength;
      } else if (spot.isPending) {
        pendingCount++;
      } else {
        otherCount++;
      }

      if (isCrumbling) {
        final qc = spot.evaluateQC(
          targetDepthCm: config.targetDepthCm,
          maxWidthCm: config.maxTrenchWidthCm,
          tolerancePercent: config.depthTolerancePercent,
        );
        qcDistribution[qc] = (qcDistribution[qc] ?? 0) + 1;

        if (spot.avgDeviationCm != null) {
          devSum += spot.avgDeviationCm!;
          devCount++;
        }
        if (spot.trenchWidthCm != null) {
          widthSum += spot.trenchWidthCm!;
          widthCount++;
        }
      }

      final spotAccuracy = spot.accuracy ?? spot.avgDeviationCm?.abs();
      if (spotAccuracy != null && spotAccuracy > 0) {
        accuracySum += spotAccuracy;
        accuracyCount++;
      }

      final spotDepth = spot.avgDepthCm ?? spot.depth;
      if (spotDepth != null) {
        depthSum += spotDepth;
        depthCount++;
      }

      // Groupings
      if (spot.isDone && spot.timestamp != null) {
        final dateKey = spot.timestamp!.toIso8601String().substring(0, 10);
        spotsByDate.putIfAbsent(dateKey, () => []).add(spot);

        final opKey = spot.operatorId?.isNotEmpty == true
            ? (spot.operatorId!.startsWith('OP-') ? spot.operatorId! : 'OP-${spot.operatorId}')
            : 'Unassigned';
        spotsByOperator.putIfAbsent(opKey, () => []).add(spot);
      }

      final eqKey = spot.equipmentId?.isNotEmpty == true
          ? (spot.equipmentId!.startsWith('EQ-') ? spot.equipmentId! : 'EQ-${spot.equipmentId}')
          : 'Unassigned';
      equipmentCounts[eqKey] = (equipmentCounts[eqKey] ?? 0) + 1;
    }

    // Footprint & Area Calculations
    final double spotFootprintM2 = config.spotAreaM2;
    double totalAreaM2 = 0.0;

    if (isCrumbling) {
      // For crumbling: jarak tempuh dikalikan panjang spacing (4m) = totalArea in m², kemudian dijadikan Ha
      final spacingMeters = config.spotLength > 0 ? config.spotLength : 4.0;
      totalAreaM2 = doneLengthMeters * spacingMeters;
    } else {
      totalAreaM2 = doneCount * spotFootprintM2;
    }

    final double totalAreaHa = totalAreaM2 / 10000.0;
    final double completionRate = isCrumbling && totalLengthMeters > 0
        ? (doneLengthMeters / totalLengthMeters) * 100.0
        : (totalSpots > 0 ? (doneCount / totalSpots) * 100.0 : 0.0);

    // Time & Speed Calculations
    doneSpotsWithTime.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));

    DateTime? minTime = doneSpotsWithTime.isNotEmpty ? doneSpotsWithTime.first.timestamp : null;
    DateTime? maxTime = doneSpotsWithTime.isNotEmpty ? doneSpotsWithTime.last.timestamp : null;

    final grossWorkHours = (minTime != null && maxTime != null)
        ? maxTime.difference(minTime).inMilliseconds / (1000.0 * 3600.0)
        : 0.0;

    final activeHours = _calculateActiveHours(doneSpotsWithTime, config.idleGapMinutes);
    final idleHours = (grossWorkHours > activeHours) ? grossWorkHours - activeHours : 0.0;

    final speedSpotsPerHour = activeHours > 0 ? (doneCount / activeHours) : 0.0;
    final speedHaPerHour = activeHours > 0 ? (totalAreaHa / activeHours) : 0.0;
    final speedMetersPerHour = activeHours > 0 ? (doneLengthMeters / activeHours) : 0.0;
    final avgSecondsPerSpot = (doneCount > 0 && activeHours > 0)
        ? (activeHours * 3600.0 / doneCount)
        : 0.0;

    // Daily breakdown
    final sortedDates = spotsByDate.keys.toList()..sort();
    final List<DailyProductivity> dailyBreakdown = [];
    for (final date in sortedDates) {
      final daySpots = spotsByDate[date]!;
      daySpots.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
      final dayActiveHours = _calculateActiveHours(daySpots, config.idleGapMinutes);

      double dayMeters = 0.0;
      double dayAreaM2 = 0.0;
      double dayDepthSum = 0.0;
      int dayDepthCount = 0;
      double dayDevSum = 0.0;
      int dayDevCount = 0;

      for (final s in daySpots) {
        final len = s.lengthMeters ?? 1.0;
        dayMeters += len;

        final d = s.avgDepthCm ?? s.depth;
        if (d != null) {
          dayDepthSum += d;
          dayDepthCount++;
        }
        if (s.avgDeviationCm != null) {
          dayDevSum += s.avgDeviationCm!;
          dayDevCount++;
        }
      }

      final spacingMeters = config.spotLength > 0 ? config.spotLength : 4.0;
      dayAreaM2 = isCrumbling ? (dayMeters * spacingMeters) : (daySpots.length * spotFootprintM2);
      final dayAreaHa = dayAreaM2 / 10000.0;
      final daySpeedSpots = dayActiveHours > 0 ? (daySpots.length / dayActiveHours) : 0.0;
      final daySpeedMeters = dayActiveHours > 0 ? (dayMeters / dayActiveHours) : 0.0;

      dailyBreakdown.add(DailyProductivity(
        date: date,
        spotsDone: daySpots.length,
        areaHa: dayAreaHa,
        activeHours: dayActiveHours,
        spotsPerHour: daySpeedSpots,
        metersDone: dayMeters,
        metersPerHour: daySpeedMeters,
        avgDepthCm: dayDepthCount > 0 ? dayDepthSum / dayDepthCount : null,
        avgDeviationCm: dayDevCount > 0 ? dayDevSum / dayDevCount : null,
      ));
    }

    // Operator breakdown
    final List<OperatorProductivity> operatorBreakdown = [];
    final sortedOps = spotsByOperator.keys.toList()..sort();
    for (final op in sortedOps) {
      final opSpots = spotsByOperator[op]!;
      opSpots.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
      final opActiveHours = _calculateActiveHours(opSpots, config.idleGapMinutes);

      double opMeters = 0.0;
      double opAreaM2 = 0.0;
      for (final s in opSpots) {
        final len = s.lengthMeters ?? 1.0;
        opMeters += len;
      }

      final spacingMeters = config.spotLength > 0 ? config.spotLength : 4.0;
      opAreaM2 = isCrumbling ? (opMeters * spacingMeters) : (opSpots.length * spotFootprintM2);
      final opAreaHa = opAreaM2 / 10000.0;
      final opSpeedSpots = opActiveHours > 0 ? (opSpots.length / opActiveHours) : 0.0;
      final opSpeedMeters = opActiveHours > 0 ? (opMeters / opActiveHours) : 0.0;

      operatorBreakdown.add(OperatorProductivity(
        operatorId: op,
        spotsCount: opSpots.length,
        areaHa: opAreaHa,
        activeHours: opActiveHours,
        spotsPerHour: opSpeedSpots,
        metersDone: opMeters,
        metersPerHour: opSpeedMeters,
      ));
    }

    return SpotSummary(
      totalSpots: totalSpots,
      doneSpots: doneCount,
      pendingSpots: pendingCount,
      inProgressSpots: inProgressCount,
      otherSpots: otherCount,
      completionRate: completionRate,
      isCrumbling: isCrumbling,
      totalLengthMeters: totalLengthMeters,
      doneLengthMeters: doneLengthMeters,
      inProgressLengthMeters: inProgressLengthMeters,
      speedMetersPerHour: speedMetersPerHour,
      avgDeviationCm: devCount > 0 ? devSum / devCount : 0.0,
      avgTrenchWidthCm: widthCount > 0 ? widthSum / widthCount : 0.0,
      qcDistribution: qcDistribution,
      spotFootprintM2: spotFootprintM2,
      totalAreaM2: totalAreaM2,
      totalAreaHa: totalAreaHa,
      activeWorkHours: activeHours,
      grossWorkHours: grossWorkHours,
      idleHours: idleHours,
      speedSpotsPerHour: speedSpotsPerHour,
      speedHaPerHour: speedHaPerHour,
      avgSecondsPerSpot: avgSecondsPerSpot,
      minTimestamp: minTime,
      maxTimestamp: maxTime,
      dailyBreakdown: dailyBreakdown,
      operatorBreakdown: operatorBreakdown,
      equipmentCounts: equipmentCounts,
      averageAccuracy: accuracyCount > 0 ? accuracySum / accuracyCount : 0.0,
      averageDepth: depthCount > 0 ? depthSum / depthCount : 0.0,
    );
  }

  static double _calculateActiveHours(List<Spot> sortedSpotsWithTime, int idleGapMinutes) {
    if (sortedSpotsWithTime.isEmpty) return 0.0;
    if (sortedSpotsWithTime.length == 1) return 0.05; // ~3 mins baseline

    final gapThresholdMs = idleGapMinutes * 60 * 1000;
    int totalActiveMs = 0;

    // Seed initial operation duration for first spot
    totalActiveMs += 15 * 1000;

    for (int i = 1; i < sortedSpotsWithTime.length; i++) {
      final prev = sortedSpotsWithTime[i - 1].timestamp!;
      final curr = sortedSpotsWithTime[i].timestamp!;
      final diff = curr.difference(prev).inMilliseconds;

      if (diff > 0 && diff <= gapThresholdMs) {
        totalActiveMs += diff;
      } else {
        // New session starting, add small base setup time
        totalActiveMs += 15 * 1000;
      }
    }

    return totalActiveMs / (1000.0 * 3600.0);
  }
}
