import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service de cache local pour les données API
/// Permet de stocker et récupérer des données de manière persistante
class ApiCacheService {
  static const String _cacheBoxName = 'api_cache';
  static const String _metadataBoxName = 'cache_metadata';

  Box<String>? _cacheBox;
  Box<int>? _metadataBox;
  bool _isInitialized = false;

  /// Instance singleton
  static final ApiCacheService _instance = ApiCacheService._internal();
  factory ApiCacheService() => _instance;
  ApiCacheService._internal();

  /// Initialise le service de cache
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      _metadataBox = await Hive.openBox<int>(_metadataBoxName);
      _isInitialized = true;

      // Nettoyer le cache expiré au démarrage
      await _cleanExpiredCache();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing cache service: $e');
      }
    }
  }

  /// Durées de cache par type de données
  static const Map<CachePolicy, Duration> _cacheDurations = {
    CachePolicy.short: Duration(minutes: 5),
    CachePolicy.medium: Duration(hours: 1),
    CachePolicy.long: Duration(hours: 24),
    CachePolicy.persistent: Duration(days: 30),
  };

  /// Stocke des données dans le cache
  Future<void> set<T>(
    String key,
    T data, {
    CachePolicy policy = CachePolicy.medium,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = jsonEncode(data);
      await _cacheBox?.put(key, jsonString);

      // Stocker le timestamp d'expiration
      final expirationTime =
          DateTime.now().add(_cacheDurations[policy]!).millisecondsSinceEpoch;
      await _metadataBox?.put('exp_$key', expirationTime);

      if (kDebugMode) {
        print('Cached: $key (expires in ${_cacheDurations[policy]})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching data for key $key: $e');
      }
    }
  }

  /// Récupère des données du cache
  Future<T?> get<T>(String key) async {
    if (!_isInitialized) await initialize();

    try {
      // Vérifier si le cache a expiré
      final expirationTime = _metadataBox?.get('exp_$key');
      if (expirationTime == null) return null;

      if (DateTime.now().millisecondsSinceEpoch > expirationTime) {
        // Cache expiré, le supprimer
        await remove(key);
        return null;
      }

      final jsonString = _cacheBox?.get(key);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as T;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving cached data for key $key: $e');
      }
      return null;
    }
  }

  /// Récupère des données du cache ou exécute le fetcher si pas en cache
  Future<T?> getOrFetch<T>(
    String key, {
    required Future<T?> Function() fetcher,
    CachePolicy policy = CachePolicy.medium,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await get<T>(key);
      if (cached != null) {
        if (kDebugMode) {
          print('Cache hit: $key');
        }
        return cached;
      }
    }

    if (kDebugMode) {
      print('Cache miss: $key - fetching...');
    }

    try {
      final data = await fetcher();
      if (data != null) {
        await set(key, data, policy: policy);
      }
      return data;
    } catch (e) {
      // En cas d'erreur, essayer de retourner le cache même s'il est expiré
      final staleCache = _cacheBox?.get(key);
      if (staleCache != null) {
        if (kDebugMode) {
          print('Returning stale cache for $key due to fetch error');
        }
        return jsonDecode(staleCache) as T;
      }
      rethrow;
    }
  }

  /// Supprime une entrée du cache
  Future<void> remove(String key) async {
    if (!_isInitialized) await initialize();

    await _cacheBox?.delete(key);
    await _metadataBox?.delete('exp_$key');
  }

  /// Supprime toutes les entrées correspondant à un préfixe
  Future<void> removeByPrefix(String prefix) async {
    if (!_isInitialized) await initialize();

    final keysToRemove = <String>[];

    for (final key in _cacheBox?.keys ?? []) {
      if (key.toString().startsWith(prefix)) {
        keysToRemove.add(key.toString());
      }
    }

    for (final key in keysToRemove) {
      await remove(key);
    }

    if (kDebugMode) {
      print(
          'Removed ${keysToRemove.length} cache entries with prefix: $prefix');
    }
  }

  /// Nettoie le cache expiré
  Future<void> _cleanExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <String>[];

    for (final key in _metadataBox?.keys ?? []) {
      final keyStr = key.toString();
      if (keyStr.startsWith('exp_')) {
        final expirationTime = _metadataBox?.get(keyStr);
        if (expirationTime != null && now > expirationTime) {
          expiredKeys.add(keyStr.substring(4)); // Remove 'exp_' prefix
        }
      }
    }

    for (final key in expiredKeys) {
      await remove(key);
    }

    if (expiredKeys.isNotEmpty && kDebugMode) {
      print('Cleaned ${expiredKeys.length} expired cache entries');
    }
  }

  /// Efface tout le cache
  Future<void> clearAll() async {
    if (!_isInitialized) await initialize();

    await _cacheBox?.clear();
    await _metadataBox?.clear();

    if (kDebugMode) {
      print('All cache cleared');
    }
  }

  /// Retourne la taille du cache en bytes (approximative)
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();

    int size = 0;
    final values = _cacheBox?.values;
    if (values != null) {
      for (final value in values) {
        size += value.length * 2; // Approximation UTF-16
      }
    }
    return size;
  }

  /// Ferme le service de cache
  Future<void> close() async {
    await _cacheBox?.close();
    await _metadataBox?.close();
    _isInitialized = false;
  }
}

/// Politique de cache définissant la durée de vie des données
enum CachePolicy {
  /// 5 minutes - pour les données qui changent fréquemment
  short,

  /// 1 heure - pour les données modérément stables
  medium,

  /// 24 heures - pour les données relativement stables
  long,

  /// 30 jours - pour les données très stables (config, etc.)
  persistent,
}

/// Clés de cache prédéfinies pour l'application
class CacheKeys {
  static String userProfile(String userId) => 'user_profile_$userId';
  static String userVehicles(String userId) => 'user_vehicles_$userId';
  static String userReservations(String userId) => 'user_reservations_$userId';
  static String notifications(String userId) => 'notifications_$userId';
  static String parkingSpots(String userId) => 'parking_spots_$userId';
  static String workerProfile(String userId) => 'worker_profile_$userId';
  static String workerJobs(String userId) => 'worker_jobs_$userId';
  static String canadianBanks() => 'canadian_banks';
  static String platformFeeConfig() => 'platform_fee_config';
}
