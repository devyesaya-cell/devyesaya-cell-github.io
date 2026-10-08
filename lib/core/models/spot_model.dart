enum CrumblingQCStatus {
  idealPass, // 🟢 Hijau (#2ECC71) - Kedalaman lolos ±10% DAN Lebar lolos <= 110 cm
  overwidth, // 🔵 Biru (#3B82F6) - Kedalaman lolos, namun parit terlalu lebar > 110 cm
  depthOutOfSpec, // 🟡 Kuning (#F59E0B) - Lebar lolos, namun kedalaman di luar ±10%
  failBoth, // 🔴 Merah (#EF4444) - Kedalaman & Lebar keduanya gagal
  inProgress, // 🟠 Oranye (#FB923C) - Sedang dikerjakan (0.1 - 0.9)
  pending, // ⚪ Abu-abu (#64748B) - Belum dikerjakan (0.0)
}

class Spot {
  final int id;
  final String uid;
  final int? pointIndex;
  final String status;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? depth;
  final DateTime? timestamp;
  final DateTime? createdAt;
  final String? operatorId;
  final String? equipmentId;
  final int? areaId;
  final int? companyId;
  final String? layer;
  final String? markerColor;
  final Map<String, dynamic> rawProperties;

  // --- LineString & Crumbling Specific Fields ---
  final bool isLineString;
  final double? startLongitude;
  final double? startLatitude;
  final double? startElevation;
  final double? endLongitude;
  final double? endLatitude;
  final double? endElevation;

  final double? lengthMeters;
  final double? minDepthCm;
  final double? maxDepthCm;
  final double? avgDepthCm;
  final double? minDeviationCm;
  final double? maxDeviationCm;
  final double? avgDeviationCm;
  final double? trenchWidthCm;
  final double? sweepProgress;
  final bool isBlock;
  final DateTime? completedAt;
  final int? spotId;
  final String? areaName;
  final String? driverId;
  final String? operatorName;

  const Spot({
    required this.id,
    required this.uid,
    this.pointIndex,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.depth,
    this.timestamp,
    this.createdAt,
    this.operatorId,
    this.equipmentId,
    this.areaId,
    this.companyId,
    this.layer,
    this.markerColor,
    this.rawProperties = const {},
    this.isLineString = false,
    this.startLongitude,
    this.startLatitude,
    this.startElevation,
    this.endLongitude,
    this.endLatitude,
    this.endElevation,
    this.lengthMeters,
    this.minDepthCm,
    this.maxDepthCm,
    this.avgDepthCm,
    this.minDeviationCm,
    this.maxDeviationCm,
    this.avgDeviationCm,
    this.trenchWidthCm,
    this.sweepProgress,
    this.isBlock = false,
    this.completedAt,
    this.spotId,
    this.areaName,
    this.driverId,
    this.operatorName,
  });

  bool get isDone => status.toLowerCase() == 'done' || isSweepDone;
  bool get isPending => status.toLowerCase() == 'pending' || isSweepPending;
  bool get isInProgress => status.toLowerCase() == 'in_progress' || isSweepInProgress;

  bool get isSweepDone => (sweepProgress ?? 0.0) >= 1.0;
  bool get isSweepInProgress => (sweepProgress ?? 0.0) > 0.0 && (sweepProgress ?? 0.0) < 1.0;
  bool get isSweepPending => (sweepProgress ?? 0.0) == 0.0;

  /// Evaluates depth compliance within ±tolerancePercent of targetDepthCm
  bool isDepthPass({required double targetDepthCm, double tolerancePercent = 10.0}) {
    final d = avgDepthCm ?? depth;
    if (d == null) return false;
    final minAllowed = targetDepthCm * (1.0 - (tolerancePercent / 100.0));
    final maxAllowed = targetDepthCm * (1.0 + (tolerancePercent / 100.0));
    return d >= minAllowed && d <= maxAllowed;
  }

  /// Evaluates trench width compliance (standard: <= 110.0 cm)
  bool isWidthPass({double maxWidthCm = 110.0}) {
    final w = trenchWidthCm;
    if (w == null) return true;
    return w <= maxWidthCm;
  }

  /// Evaluates 4-Quadrant QC status according to CRUMBLING_TARGET_DEPTH_CONFIG_MANUAL.md
  CrumblingQCStatus evaluateQC({
    required double targetDepthCm,
    double maxWidthCm = 110.0,
    double tolerancePercent = 10.0,
  }) {
    if (isSweepPending) return CrumblingQCStatus.pending;
    if (isSweepInProgress) return CrumblingQCStatus.inProgress;

    final depthOk = isDepthPass(targetDepthCm: targetDepthCm, tolerancePercent: tolerancePercent);
    final widthOk = isWidthPass(maxWidthCm: maxWidthCm);

    if (depthOk && widthOk) return CrumblingQCStatus.idealPass;
    if (depthOk && !widthOk) return CrumblingQCStatus.overwidth;
    if (!depthOk && widthOk) return CrumblingQCStatus.depthOutOfSpec;
    return CrumblingQCStatus.failBoth;
  }

  static String qcStatusToHex(CrumblingQCStatus status) {
    switch (status) {
      case CrumblingQCStatus.idealPass:
        return '#2ECC71'; // Green
      case CrumblingQCStatus.overwidth:
        return '#3B82F6'; // Blue
      case CrumblingQCStatus.depthOutOfSpec:
        return '#F59E0B'; // Amber / Yellow
      case CrumblingQCStatus.failBoth:
        return '#EF4444'; // Red
      case CrumblingQCStatus.inProgress:
        return '#FB923C'; // Orange
      case CrumblingQCStatus.pending:
        return '#64748B'; // Slate Grey
    }
  }

  String getQCColorHex({
    required double targetDepthCm,
    double maxWidthCm = 110.0,
    double tolerancePercent = 10.0,
  }) {
    return qcStatusToHex(evaluateQC(
      targetDepthCm: targetDepthCm,
      maxWidthCm: maxWidthCm,
      tolerancePercent: tolerancePercent,
    ));
  }

  factory Spot.fromGeoJson(Map<String, dynamic> feature, int fallbackId) {
    final properties = (feature['properties'] as Map<String, dynamic>?) ?? {};
    final geometry = (feature['geometry'] as Map<String, dynamic>?) ?? {};
    final geomType = geometry['type']?.toString() ?? 'Point';
    final rawCoords = geometry['coordinates'];

    final rawId = properties['id'];
    final id = rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? fallbackId);

    if (geomType == 'LineString' && rawCoords is List && rawCoords.isNotEmpty) {
      // LineString geometry handling: [[lng1, lat1, elev1], [lng2, lat2, elev2]]
      final start = rawCoords[0] is List ? rawCoords[0] as List : [0.0, 0.0];
      final end = (rawCoords.length > 1 && rawCoords[1] is List) ? rawCoords[1] as List : start;

      final startLng = (start.isNotEmpty ? (start[0] as num).toDouble() : 0.0);
      final startLat = (start.length > 1 ? (start[1] as num).toDouble() : 0.0);
      final startAlt = start.length > 2 ? (start[2] as num).toDouble() : null;

      final endLng = (end.isNotEmpty ? (end[0] as num).toDouble() : startLng);
      final endLat = (end.length > 1 ? (end[1] as num).toDouble() : startLat);
      final endAlt = end.length > 2 ? (end[2] as num).toDouble() : startAlt;

      final midLng = (startLng + endLng) / 2.0;
      final midLat = (startLat + endLat) / 2.0;

      final lengthMeters = (properties['length_meters'] as num?)?.toDouble();
      final avgDepthCm = (properties['avg_depth_cm'] as num?)?.toDouble();
      final minDepthCm = (properties['min_depth_cm'] as num?)?.toDouble();
      final maxDepthCm = (properties['max_depth_cm'] as num?)?.toDouble();
      final avgDevCm = (properties['avg_deviation_cm'] as num?)?.toDouble();
      final minDevCm = (properties['min_deviation_cm'] as num?)?.toDouble();
      final maxDevCm = (properties['max_deviation_cm'] as num?)?.toDouble();
      final trenchWidthCm = (properties['trench_width_cm'] as num?)?.toDouble();
      final sweepProgress = (properties['sweep_progress'] as num?)?.toDouble() ?? 1.0;
      final isBlock = properties['is_block'] == true;

      DateTime? completedAt;
      if (properties['completed_at'] != null) {
        final val = properties['completed_at'];
        if (val is int) {
          completedAt = DateTime.fromMillisecondsSinceEpoch(val * 1000);
        } else {
          final parsed = int.tryParse(val.toString());
          if (parsed != null) {
            completedAt = DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
          }
        }
      }

      final spotId = properties['spot_id'] is int
          ? properties['spot_id'] as int
          : int.tryParse(properties['spot_id']?.toString() ?? '');

      final areaName = properties['area_name']?.toString();
      final driverId = properties['driver_id']?.toString();
      final operatorName = properties['operator_name']?.toString();

      String status = 'pending';
      if (sweepProgress >= 1.0 || completedAt != null) {
        status = 'done';
      } else if (sweepProgress > 0.0) {
        status = 'in_progress';
      }

      final uid = properties['file_id'] != null
          ? '${properties['file_id']}-$id'
          : 'seg-$id';

      return Spot(
        id: id,
        uid: uid,
        pointIndex: spotId,
        status: status,
        latitude: midLat,
        longitude: midLng,
        accuracy: avgDevCm != null ? (avgDevCm.abs()) : null,
        depth: avgDepthCm,
        timestamp: completedAt,
        createdAt: completedAt,
        operatorId: driverId ?? operatorName,
        equipmentId: operatorName,
        layer: 'crumbling',
        markerColor: null,
        rawProperties: properties,
        isLineString: true,
        startLongitude: startLng,
        startLatitude: startLat,
        startElevation: startAlt,
        endLongitude: endLng,
        endLatitude: endLat,
        endElevation: endAlt,
        lengthMeters: lengthMeters,
        minDepthCm: minDepthCm,
        maxDepthCm: maxDepthCm,
        avgDepthCm: avgDepthCm,
        minDeviationCm: minDevCm,
        maxDeviationCm: maxDevCm,
        avgDeviationCm: avgDevCm,
        trenchWidthCm: trenchWidthCm,
        sweepProgress: sweepProgress,
        isBlock: isBlock,
        completedAt: completedAt,
        spotId: spotId,
        areaName: areaName,
        driverId: driverId,
        operatorName: operatorName,
      );
    }

    // Default: Point Geometry
    final coords = (rawCoords is List) ? rawCoords : [0.0, 0.0];
    final double lng = (coords.isNotEmpty && coords[0] is num ? (coords[0] as num).toDouble() : 0.0);
    final double lat = (coords.length > 1 && coords[1] is num ? (coords[1] as num).toDouble() : 0.0);

    final uid = properties['uid']?.toString() ?? 'spot-$id';
    final pointIndex = properties['point_index'] is int
        ? properties['point_index'] as int
        : int.tryParse(properties['point_index']?.toString() ?? '');

    final status = properties['status']?.toString().toLowerCase() ?? 'unknown';

    final accuracy = properties['accuracy'] != null
        ? (properties['accuracy'] as num).toDouble()
        : null;

    final depth = properties['depth'] != null
        ? (properties['depth'] as num).toDouble()
        : null;

    DateTime? timestamp;
    if (properties['timestamp'] != null) {
      timestamp = DateTime.tryParse(properties['timestamp'].toString());
    }

    DateTime? createdAt;
    if (properties['created_at'] != null) {
      createdAt = DateTime.tryParse(properties['created_at'].toString());
    }

    final operatorId = properties['operator_id']?.toString();
    final equipmentId = properties['equipment_id']?.toString();

    final areaId = properties['area_id'] is int
        ? properties['area_id'] as int
        : int.tryParse(properties['area_id']?.toString() ?? '');

    final companyId = properties['company_id'] is int
        ? properties['company_id'] as int
        : int.tryParse(properties['company_id']?.toString() ?? '');

    final layer = properties['layer']?.toString();
    final markerColor = properties['marker-color']?.toString();

    return Spot(
      id: id,
      uid: uid,
      pointIndex: pointIndex,
      status: status,
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      depth: depth,
      timestamp: timestamp,
      createdAt: createdAt,
      operatorId: operatorId,
      equipmentId: equipmentId,
      areaId: areaId,
      companyId: companyId,
      layer: layer,
      markerColor: markerColor,
      rawProperties: properties,
      isLineString: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'point_index': pointIndex,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'depth': depth,
      'timestamp': timestamp?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'operator_id': operatorId,
      'equipment_id': equipmentId,
      'area_id': areaId,
      'company_id': companyId,
      'layer': layer,
      'marker_color': markerColor,
      'is_line_string': isLineString,
      'start_longitude': startLongitude,
      'start_latitude': startLatitude,
      'start_elevation': startElevation,
      'end_longitude': endLongitude,
      'end_latitude': endLatitude,
      'end_elevation': endElevation,
      'length_meters': lengthMeters,
      'min_depth_cm': minDepthCm,
      'max_depth_cm': maxDepthCm,
      'avg_depth_cm': avgDepthCm,
      'min_deviation_cm': minDeviationCm,
      'max_deviation_cm': maxDeviationCm,
      'avg_deviation_cm': avgDeviationCm,
      'trench_width_cm': trenchWidthCm,
      'sweep_progress': sweepProgress,
      'is_block': isBlock,
      'completed_at': completedAt?.toIso8601String(),
      'spot_id': spotId,
      'area_name': areaName,
      'driver_id': driverId,
      'operator_name': operatorName,
    };
  }

  factory Spot.fromMap(Map<String, dynamic> map) {
    return Spot(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      uid: map['uid']?.toString() ?? '',
      pointIndex: map['point_index'] as int?,
      status: map['status']?.toString() ?? 'unknown',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      depth: (map['depth'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      operatorId: map['operator_id']?.toString(),
      equipmentId: map['equipment_id']?.toString(),
      areaId: map['area_id'] as int?,
      companyId: map['company_id'] as int?,
      layer: map['layer']?.toString(),
      markerColor: map['marker_color']?.toString(),
      rawProperties: map,
      isLineString: map['is_line_string'] == true,
      startLongitude: (map['start_longitude'] as num?)?.toDouble(),
      startLatitude: (map['start_latitude'] as num?)?.toDouble(),
      startElevation: (map['start_elevation'] as num?)?.toDouble(),
      endLongitude: (map['end_longitude'] as num?)?.toDouble(),
      endLatitude: (map['end_latitude'] as num?)?.toDouble(),
      endElevation: (map['end_elevation'] as num?)?.toDouble(),
      lengthMeters: (map['length_meters'] as num?)?.toDouble(),
      minDepthCm: (map['min_depth_cm'] as num?)?.toDouble(),
      maxDepthCm: (map['max_depth_cm'] as num?)?.toDouble(),
      avgDepthCm: (map['avg_depth_cm'] as num?)?.toDouble(),
      minDeviationCm: (map['min_deviation_cm'] as num?)?.toDouble(),
      maxDeviationCm: (map['max_deviation_cm'] as num?)?.toDouble(),
      avgDeviationCm: (map['avg_deviation_cm'] as num?)?.toDouble(),
      trenchWidthCm: (map['trench_width_cm'] as num?)?.toDouble(),
      sweepProgress: (map['sweep_progress'] as num?)?.toDouble(),
      isBlock: map['is_block'] == true,
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at']) : null,
      spotId: map['spot_id'] as int?,
      areaName: map['area_name']?.toString(),
      driverId: map['driver_id']?.toString(),
      operatorName: map['operator_name']?.toString(),
    );
  }
}
