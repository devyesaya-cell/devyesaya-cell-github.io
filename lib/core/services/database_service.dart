import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/config_model.dart';
import '../models/spot_model.dart';

class DatabaseService {
  static const String _metadataBoxName = 'spot_metadata';
  static const String _dataBoxName = 'spot_data_chunks';
  static const int _chunkSize = 2500;

  static Box? _metadataBox;
  static Box? _dataBox;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _metadataBox = await Hive.openBox(_metadataBoxName);
      _dataBox = await Hive.openBox(_dataBoxName);
    } catch (e) {
      debugPrint('DatabaseService init error: $e');
    }
  }

  static Future<void> saveDataset({
    required String name,
    required List<Spot> spots,
  }) async {
    if (_metadataBox == null || _dataBox == null) await initialize();

    try {
      // Clear previous chunks
      await _dataBox?.clear();

      // Store in chunks for optimum Web IndexedDB performance
      final int totalChunks = (spots.length / _chunkSize).ceil();
      for (int i = 0; i < totalChunks; i++) {
        final start = i * _chunkSize;
        final end = (start + _chunkSize < spots.length) ? start + _chunkSize : spots.length;
        final chunk = spots.sublist(start, end).map((s) => s.toMap()).toList();
        await _dataBox?.put('chunk_$i', json.encode(chunk));
      }

      await _metadataBox?.put('dataset_name', name);
      await _metadataBox?.put('total_spots', spots.length);
      await _metadataBox?.put('chunk_count', totalChunks);
      await _metadataBox?.put('saved_at', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving dataset: $e');
      rethrow;
    }
  }

  static Future<List<Spot>?> loadDataset() async {
    if (_metadataBox == null || _dataBox == null) await initialize();

    try {
      final totalSpots = _metadataBox?.get('total_spots') as int?;
      if (totalSpots == null || totalSpots == 0) return null;

      final chunkCount = _metadataBox?.get('chunk_count') as int? ?? 0;
      final List<Spot> result = [];

      for (int i = 0; i < chunkCount; i++) {
        final rawChunk = _dataBox?.get('chunk_$i');
        if (rawChunk != null) {
          final List<dynamic> list = json.decode(rawChunk.toString());
          for (final item in list) {
            result.add(Spot.fromMap(Map<String, dynamic>.from(item as Map)));
          }
        }
      }

      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('Error loading dataset: $e');
      return null;
    }
  }

  static String? getDatasetName() {
    return _metadataBox?.get('dataset_name') as String?;
  }

  static Future<void> saveConfig(SpotConfig config) async {
    if (_metadataBox == null) await initialize();
    await _metadataBox?.put('app_config', config.toMap());
  }

  static SpotConfig loadConfig() {
    if (_metadataBox == null) return const SpotConfig();
    final map = _metadataBox?.get('app_config');
    if (map != null && map is Map) {
      return SpotConfig.fromMap(Map<String, dynamic>.from(map));
    }
    return const SpotConfig();
  }

  static Future<void> clearAll() async {
    if (_metadataBox == null || _dataBox == null) await initialize();
    await _dataBox?.clear();
    await _metadataBox?.delete('dataset_name');
    await _metadataBox?.delete('total_spots');
    await _metadataBox?.delete('chunk_count');
    await _metadataBox?.delete('saved_at');
  }
}
