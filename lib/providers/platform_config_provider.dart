import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import '../core/storage/api_cache_store.dart';
import '../domain/entities/platform_config.dart';

class PlatformConfigNotifier extends StateNotifier<PlatformConfig> {
  final Dio _dio;
  final ApiCacheStore _cache;
  PlatformConfigNotifier(this._dio, this._cache)
      : super(PlatformConfig.fallback) {
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/app-config');
      if (response.data != null) {
        state = PlatformConfig.fromJson(response.data!);
        await _cache.writeObject('platform_config', response.data!);
      }
    } catch (_) {
      final cached = await _cache.readObject('platform_config');
      state = cached == null
          ? PlatformConfig.fallback
          : PlatformConfig.fromJson({...cached, 'demoMode': true});
    }
  }
}

final platformConfigProvider =
    StateNotifierProvider<PlatformConfigNotifier, PlatformConfig>((ref) =>
        PlatformConfigNotifier(
            ref.watch(dioProvider), ref.watch(apiCacheStoreProvider)));
