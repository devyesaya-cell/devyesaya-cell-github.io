import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_monitoring/core/models/config_model.dart';
import 'package:spot_monitoring/core/models/spot_model.dart';
import 'package:spot_monitoring/core/utils/calculation_engine.dart';
import 'package:spot_monitoring/core/utils/geojson_parser.dart';

void main() {
  group('Crumbling GeoJSON Parser & QC Coloring Tests', () {
    test('Correctly parses actual crumbling GeoJSON file with 6452 features', () {
      final file = File('docs/crumbling_results_Area1_Badak_Culah_20261007_170409.geojson');
      expect(file.existsSync(), isTrue, reason: 'GeoJSON file must exist in docs/');

      final content = file.readAsStringSync();
      final result = GeoJsonParser.parseString(content);

      expect(result.totalFeatures, equals(6452));
      expect(result.spots.length, equals(6452));
      expect(result.isCrumbling, isTrue);

      // Verify global metrics
      expect(result.totalLengthMeters, closeTo(4325.87, 0.5));
      expect(result.avgDepthCm!, closeTo(71.05, 0.5));
      expect(result.avgDeviationCm!, closeTo(18.08, 0.5));
      expect(result.avgTrenchWidthCm!, closeTo(120.62, 0.5));

      // Progress breakdown
      expect(result.doneCount, equals(3372));
      expect(result.inProgressCount, equals(1394));
      expect(result.pendingCount, equals(1686));

      // Verify individual spot properties on feature 0
      final first = result.spots.first;
      expect(first.isLineString, isTrue);
      expect(first.id, equals(2660));
      expect(first.areaName, equals('Area1'));
      expect(first.operatorName, equals('Badak Culah'));
      expect(first.spotId, equals(1));
      expect(first.lengthMeters!, closeTo(1.0001, 0.001));
      expect(first.avgDepthCm, equals(69.0));
      expect(first.minDepthCm, equals(60.0));
      expect(first.maxDepthCm, equals(89.0));
      expect(first.trenchWidthCm!, closeTo(104.2, 0.1));
      expect(first.sweepProgress, equals(1.0));
      expect(first.isBlock, isFalse);
      expect(first.completedAt, isNotNull);

      // Verify coordinates
      expect(first.startLongitude!, closeTo(101.61446, 0.0001));
      expect(first.startLatitude!, closeTo(0.72947, 0.0001));
      expect(first.endLongitude!, closeTo(101.61447, 0.0001));
      expect(first.endLatitude!, closeTo(0.72947, 0.0001));
      expect(first.longitude, closeTo(101.614468, 0.0001));
      expect(first.latitude, closeTo(0.729474, 0.0001));
    });

    test('Evaluates 4-Quadrant QC logic correctly against CRUMBLING_TARGET_DEPTH_CONFIG_MANUAL.md', () {
      const targetDepth = 70.0; // cm
      const maxTrenchWidth = 110.0; // cm

      // 1. Ideal Pass: depth within 63 - 77 cm (±10%), width <= 110 cm -> Green (#2ECC71)
      final idealSpot = Spot(
        id: 1,
        uid: 'test-ideal',
        status: 'done',
        latitude: 0,
        longitude: 0,
        sweepProgress: 1.0,
        avgDepthCm: 69.0, // within 63..77
        trenchWidthCm: 104.0, // <= 110
      );
      expect(idealSpot.evaluateQC(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals(CrumblingQCStatus.idealPass));
      expect(idealSpot.getQCColorHex(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals('#2ECC71'));

      // 2. Overwidth: depth ok (69cm), but width too wide (125cm > 110cm) -> Blue (#3B82F6)
      final overwidthSpot = Spot(
        id: 2,
        uid: 'test-overwidth',
        status: 'done',
        latitude: 0,
        longitude: 0,
        sweepProgress: 1.0,
        avgDepthCm: 69.0, // within 63..77
        trenchWidthCm: 125.0, // > 110
      );
      expect(overwidthSpot.evaluateQC(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals(CrumblingQCStatus.overwidth));
      expect(overwidthSpot.getQCColorHex(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals('#3B82F6'));

      // 3. Depth out of spec: width ok (102cm), but depth out of bounds (92cm > 77cm) -> Yellow (#F59E0B)
      final depthOutSpot = Spot(
        id: 3,
        uid: 'test-depth-out',
        status: 'done',
        latitude: 0,
        longitude: 0,
        sweepProgress: 1.0,
        avgDepthCm: 92.0, // > 77
        trenchWidthCm: 102.0, // <= 110
      );
      expect(depthOutSpot.evaluateQC(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals(CrumblingQCStatus.depthOutOfSpec));
      expect(depthOutSpot.getQCColorHex(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals('#F59E0B'));

      // 4. Fail Both: depth out of bounds (50cm < 63cm) AND width too wide (120cm > 110cm) -> Red (#EF4444)
      final failBothSpot = Spot(
        id: 4,
        uid: 'test-fail-both',
        status: 'done',
        latitude: 0,
        longitude: 0,
        sweepProgress: 1.0,
        avgDepthCm: 50.0, // < 63
        trenchWidthCm: 120.0, // > 110
      );
      expect(failBothSpot.evaluateQC(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals(CrumblingQCStatus.failBoth));
      expect(failBothSpot.getQCColorHex(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals('#EF4444'));

      // 5. In-Progress: sweepProgress between 0 and 1 -> Orange (#FB923C)
      final inProgressSpot = Spot(
        id: 5,
        uid: 'test-in-progress',
        status: 'in_progress',
        latitude: 0,
        longitude: 0,
        sweepProgress: 0.6,
        avgDepthCm: 69.0,
        trenchWidthCm: 104.0,
      );
      expect(inProgressSpot.evaluateQC(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals(CrumblingQCStatus.inProgress));
      expect(inProgressSpot.getQCColorHex(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals('#FB923C'));

      // 6. Pending: sweepProgress == 0 -> Grey (#64748B)
      final pendingSpot = Spot(
        id: 6,
        uid: 'test-pending',
        status: 'pending',
        latitude: 0,
        longitude: 0,
        sweepProgress: 0.0,
      );
      expect(pendingSpot.evaluateQC(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals(CrumblingQCStatus.pending));
      expect(pendingSpot.getQCColorHex(targetDepthCm: targetDepth, maxWidthCm: maxTrenchWidth),
          equals('#64748B'));
    });

    test('Backward compatibility: Point GeoJSON features still parse properly', () {
      const samplePointGeoJson = '''
{
  "type": "FeatureCollection",
  "name": "Sample_Points",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [101.55, 1.05]
      },
      "properties": {
        "id": 101,
        "status": "done",
        "depth": 0.85,
        "accuracy": 0.02
      }
    }
  ]
}
''';
      final result = GeoJsonParser.parseString(samplePointGeoJson);
      expect(result.totalFeatures, equals(1));
      expect(result.spots.length, equals(1));
      expect(result.isCrumbling, isFalse);

      final pt = result.spots.first;
      expect(pt.isLineString, isFalse);
      expect(pt.longitude, equals(101.55));
      expect(pt.latitude, equals(1.05));
      expect(pt.isDone, isTrue);
      expect(pt.depth, equals(0.85));
      expect(pt.accuracy, equals(0.02));
    });

    test('SpotConfig handles targetDepthCm and legacy targetDepth serialization', () {
      const config = SpotConfig(
        targetDepthCm: 70.0,
        maxTrenchWidthCm: 110.0,
        depthTolerancePercent: 10.0,
      );

      expect(config.minAllowedDepthCm, equals(63.0));
      expect(config.maxAllowedDepthCm, equals(77.0));

      final map = config.toMap();
      expect(map['targetDepthCm'], equals(70.0));
      expect(map['maxTrenchWidthCm'], equals(110.0));

      final restored = SpotConfig.fromMap(map);
      expect(restored.targetDepthCm, equals(70.0));
      expect(restored.maxTrenchWidthCm, equals(110.0));
      expect(restored.minAllowedDepthCm, equals(63.0));
      expect(restored.maxAllowedDepthCm, equals(77.0));
    });

    test('CalculationEngine correctly computes crumbling summary, length, and QC distribution', () {
      final file = File('docs/crumbling_results_Area1_Badak_Culah_20261007_170409.geojson');
      final result = GeoJsonParser.parseString(file.readAsStringSync());

      const config = SpotConfig(
        targetDepthCm: 70.0,
        maxTrenchWidthCm: 110.0,
        depthTolerancePercent: 10.0,
      );

      final summary = CalculationEngine.calculate(spots: result.spots, config: config);

      expect(summary.isCrumbling, isTrue);
      expect(summary.totalSpots, equals(6452));
      expect(summary.totalLengthMeters, closeTo(4325.87, 0.5));
      expect(summary.doneLengthMeters, greaterThan(2000.0));
      expect(summary.averageDepth, closeTo(71.05, 0.5));
      expect(summary.avgDeviationCm, closeTo(18.08, 0.5));
      expect(summary.avgTrenchWidthCm, closeTo(120.62, 0.5));

      // Area is calculated as distance covered * spacing (4m) = totalArea in m² and Ha
      expect(summary.totalAreaM2, closeTo(summary.doneLengthMeters * 4.0, 0.01));
      expect(summary.totalAreaHa, closeTo(summary.totalAreaM2 / 10000.0, 0.0001));
      expect(summary.totalAreaHa, greaterThan(0.8));

      // QC 4-Quadrant distribution
      expect(summary.qcDistribution, isNotEmpty);
      expect(summary.qcDistribution[CrumblingQCStatus.idealPass]!, greaterThan(0));
      expect(summary.qcDistribution[CrumblingQCStatus.overwidth]!, greaterThan(0));
      expect(summary.qcDistribution[CrumblingQCStatus.pending]!, equals(1686));

      // Daily breakdown contains meters
      expect(summary.dailyBreakdown, isNotEmpty);
      final topDay = summary.dailyBreakdown.firstWhere((d) => d.date == '2026-09-23');
      expect(topDay.metersDone, closeTo(242.39, 0.5));
      expect(topDay.spotsDone, equals(1135));

      // Operator breakdown
      expect(summary.operatorBreakdown, isNotEmpty);
      expect(summary.operatorBreakdown.first.metersDone, greaterThan(2000.0));
    });
  });
}
