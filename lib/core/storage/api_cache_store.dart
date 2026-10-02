import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

abstract class ApiCacheStore {
  Future<List<Map<String, dynamic>>?> readList(String key);
  Future<void> writeList(String key, List<Map<String, dynamic>> value);
  Future<Map<String, dynamic>?> readObject(String key);
  Future<void> writeObject(String key, Map<String, dynamic> value);
}

class HiveApiCacheStore implements ApiCacheStore {
  static const boxName = 'api_cache';

  Box<String> get _box => Hive.box<String>(boxName);

  @override
  Future<List<Map<String, dynamic>>?> readList(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> value) =>
      _box.put(key, jsonEncode(value));

  @override
  Future<Map<String, dynamic>?> readObject(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeObject(String key, Map<String, dynamic> value) =>
      _box.put(key, jsonEncode(value));
}
