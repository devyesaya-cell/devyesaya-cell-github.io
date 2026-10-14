import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_monitoring/core/models/config_model.dart';
import 'package:spot_monitoring/core/models/spot_model.dart';
import 'package:spot_monitoring/core/utils/calculation_engine.dart';
import 'package:spot_monitoring/core/utils/geojson_parser.dart';

void main() {
  group('Spot Interval Time (Cycle Time) Calculation Tests', () {
    test('Correctly computes Min, Max, and Avg interval on synthetic spots', () {
      final baseTime = DateTime.parse('2026-10-14T08:00:00Z');

      final spots = [
        Spot(
          id: 1,
          uid: 's1',
          status: 'done',
          latitude: 0,
          longitude: 0,
          timestamp: baseTime,
          operatorId: 'OP-1',
        ),
        Spot(
          id: 2,
          uid: 's2',
          status: 'done',
          latitude: 0,
          longitude: 0,
          timestamp: baseTime.add(const Duration(seconds: 15)), // +15s (Min)
          operatorId: 'OP-1',
        ),
        Spot(
          id: 3,
          uid: 's3',
          status: 'done',
          latitude: 0,
          longitude: 0,
          timestamp: baseTime.add(const Duration(seconds: 40)), // +25s
          operatorId: 'OP-1',
        ),
        Spot(
          id: 4,
          uid: 's4',
          status: 'done',
          latitude: 0,
          longitude: 0,
          timestamp: baseTime.add(const Duration(seconds: 90)), // +50s (Max)
          operatorId: 'OP-1',
        ),
        Spot(
          id: 5,
          uid: 's5',
          status: 'done',
          latitude: 0,
          longitude: 0,
          timestamp: baseTime.add(const Duration(minutes: 30)), // +28.5 mins (> idle gap, excluded)
          operatorId: 'OP-1',
        ),
      ];

      const config = SpotConfig(idleGapMinutes: 10);
      final summary = CalculationEngine.calculate(spots: spots, config: config);

      expect(summary.minSecondsPerSpot, equals(15.0));
      expect(summary.maxSecondsPerSpot, equals(50.0));
      expect(summary.operatorBreakdown, isNotEmpty);

      final op = summary.operatorBreakdown.first;
      expect(op.minSecondsPerSpot, equals(15.0));
      expect(op.maxSecondsPerSpot, equals(50.0));
      expect(op.avgSecondsPerSpot, closeTo((15.0 + 25.0 + 50.0) / 3.0, 0.01));
    });

    test('Correctly computes Min, Max, and Avg interval on actual SBAE035803.geojson', () {
      final file = File('assets/data/SBAE035803.geojson');
      expect(file.existsSync(), isTrue);

      final result = GeoJsonParser.parseString(file.readAsStringSync());
      expect(result.spots, isNotEmpty);

      const config = SpotConfig(idleGapMinutes: 10);
      final summary = CalculationEngine.calculate(spots: result.spots, config: config);

      expect(summary.doneSpots, greaterThan(0));
      expect(summary.minSecondsPerSpot, greaterThan(0.0));
      expect(summary.maxSecondsPerSpot, greaterThan(summary.minSecondsPerSpot));
      expect(summary.avgSecondsPerSpot, greaterThan(0.0));

      // Min spot interval should be reasonable for excavator operation (> 0 and <= 30s)
      expect(summary.minSecondsPerSpot, inInclusiveRange(1.0, 30.0));
      // Max operational interval before idle threshold (<= 10 mins = 600s)
      expect(summary.maxSecondsPerSpot, lessThanOrEqualTo(600.0));
    });
  });
}
