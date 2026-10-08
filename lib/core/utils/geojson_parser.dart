import 'dart:convert';
import 'dart:typed_data';
import '../models/spot_model.dart';

class DatasetResult {
  final String name;
  final List<Spot> spots;
  final int totalFeatures;
  final DateTime parsedAt;
  final bool isCrumbling;
  final double totalLengthMeters;
  final double? avgDepthCm;
  final double? avgDeviationCm;
  final double? avgTrenchWidthCm;
  final int doneCount;
  final int inProgressCount;
  final int pendingCount;

  const DatasetResult({
    required this.name,
    required this.spots,
    required this.totalFeatures,
    required this.parsedAt,
    this.isCrumbling = false,
    this.totalLengthMeters = 0.0,
    this.avgDepthCm,
    this.avgDeviationCm,
    this.avgTrenchWidthCm,
    this.doneCount = 0,
    this.inProgressCount = 0,
    this.pendingCount = 0,
  });
}

class GeoJsonParser {
  static DatasetResult parseString(String jsonContent, {String? defaultName}) {
    final Map<String, dynamic> data = json.decode(jsonContent);
    return _processJsonMap(data, defaultName);
  }

  static DatasetResult parseBytes(Uint8List bytes, {String? defaultName}) {
    final String content = utf8.decode(bytes);
    return parseString(content, defaultName: defaultName);
  }

  static DatasetResult _processJsonMap(Map<String, dynamic> data, String? defaultName) {
    final type = data['type']?.toString();
    if (type != 'FeatureCollection' && !data.containsKey('features')) {
      throw const FormatException('File is not a valid GeoJSON FeatureCollection');
    }

    final rawName = data['name']?.toString() ?? defaultName ?? 'SBAE_Spots';
    final features = (data['features'] as List<dynamic>?) ?? [];

    final List<Spot> spots = [];
    int lineStringCount = 0;
    double totalLengthMeters = 0.0;
    double depthSum = 0.0;
    int depthCount = 0;
    double devSum = 0.0;
    int devCount = 0;
    double widthSum = 0.0;
    int widthCount = 0;
    int doneCount = 0;
    int inProgressCount = 0;
    int pendingCount = 0;

    for (int i = 0; i < features.length; i++) {
      final f = features[i];
      if (f is Map<String, dynamic>) {
        try {
          final spot = Spot.fromGeoJson(f, i + 1);
          spots.add(spot);

          if (spot.isLineString) {
            lineStringCount++;
            if (spot.lengthMeters != null) {
              totalLengthMeters += spot.lengthMeters!;
            }
            if (spot.avgDepthCm != null) {
              depthSum += spot.avgDepthCm!;
              depthCount++;
            }
            if (spot.avgDeviationCm != null) {
              devSum += spot.avgDeviationCm!;
              devCount++;
            }
            if (spot.trenchWidthCm != null) {
              widthSum += spot.trenchWidthCm!;
              widthCount++;
            }

            if (spot.isSweepDone) {
              doneCount++;
            } else if (spot.isSweepInProgress) {
              inProgressCount++;
            } else {
              pendingCount++;
            }
          } else {
            if (spot.isDone) {
              doneCount++;
            } else {
              pendingCount++;
            }
          }
        } catch (_) {
          // Skip corrupted single feature
        }
      }
    }

    final bool isCrumbling = lineStringCount > 0 ||
        rawName.toLowerCase().contains('crumbling') ||
        (spots.isNotEmpty && spots.first.isLineString);

    return DatasetResult(
      name: rawName,
      spots: spots,
      totalFeatures: features.length,
      parsedAt: DateTime.now(),
      isCrumbling: isCrumbling,
      totalLengthMeters: totalLengthMeters,
      avgDepthCm: depthCount > 0 ? (depthSum / depthCount) : null,
      avgDeviationCm: devCount > 0 ? (devSum / devCount) : null,
      avgTrenchWidthCm: widthCount > 0 ? (widthSum / widthCount) : null,
      doneCount: doneCount,
      inProgressCount: inProgressCount,
      pendingCount: pendingCount,
    );
  }
}
