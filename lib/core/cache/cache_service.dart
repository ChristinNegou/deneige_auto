import 'package:hive_flutter/hive_flutter.dart';

/// Service de cache generique pour le stockage local
abstract class CacheService {
  Future<void> init();
  Future<T?> get<T>(String key);
  Future<void> put<T>(String key, T value);
  Future<void> delete(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
  Future<List<T>> getAll<T>();
  Future<void> putAll<T>(String key, List<T> values);
}

/// Implementation Hive du service de cache
class HiveCacheService implements CacheService {
  final String boxName;
  late Box<dynamic> _box;
  bool _isInitialized = false;

  HiveCacheService({required this.boxName});

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('CacheService not initialized. Call init() first.');
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    _ensureInitialized();
    return _box.get(key) as T?;
  }

  @override
  Future<void> put<T>(String key, T value) async {
    _ensureInitialized();
    await _box.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    await _box.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    _ensureInitialized();
    return _box.containsKey(key);
  }

  @override
  Future<List<T>> getAll<T>() async {
    _ensureInitialized();
    return _box.values.cast<T>().toList();
  }

  @override
  Future<void> putAll<T>(String key, List<T> values) async {
    _ensureInitialized();
    await _box.put(key, values);
  }
}

/// Cache avec expiration automatique
class ExpiringCacheService implements CacheService {
  final HiveCacheService _cache;
  final Duration defaultExpiration;
  static const String _expirationSuffix = '_expiration';

  ExpiringCacheService({
    required String boxName,
    this.defaultExpiration = const Duration(hours: 24),
  }) : _cache = HiveCacheService(boxName: boxName);

  @override
  Future<void> init() => _cache.init();

  @override
  Future<T?> get<T>(String key) async {
    final expirationKey = '$key$_expirationSuffix';
    final expiration = await _cache.get<int>(expirationKey);

    if (expiration != null) {
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(expiration);
      if (DateTime.now().isAfter(expirationDate)) {
        await delete(key);
        return null;
      }
    }

    return _cache.get<T>(key);
  }

  Future<void> putWithExpiration<T>(String key, T value,
      {Duration? expiration}) async {
    final exp = expiration ?? defaultExpiration;
    final expirationDate = DateTime.now().add(exp);
    final expirationKey = '$key$_expirationSuffix';

    await _cache.put(key, value);
    await _cache.put(expirationKey, expirationDate.millisecondsSinceEpoch);
  }

  @override
  Future<void> put<T>(String key, T value) async {
    await putWithExpiration(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _cache.delete(key);
    await _cache.delete('$key$_expirationSuffix');
  }

  @override
  Future<void> clear() => _cache.clear();

  @override
  Future<bool> containsKey(String key) async {
    final value = await get<dynamic>(key);
    return value != null;
  }

  @override
  Future<List<T>> getAll<T>() => _cache.getAll<T>();

  @override
  Future<void> putAll<T>(String key, List<T> values) async {
    await putWithExpiration(key, values);
  }
}
