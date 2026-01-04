import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache pour les reservations et vehicules
/// Stocke les donnees sous forme de JSON brut pour eviter
/// les problemes de serialisation avec les entites complexes
class ReservationCache {
  static const String _boxName = 'reservation_cache';
  static const String _reservationsKey = 'reservations_json';
  static const String _vehiclesKey = 'vehicles_json';
  static const String _lastSyncKey = 'last_sync';
  static const String _pendingActionsKey = 'pending_actions';

  late Box<dynamic> _box;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ReservationCache not initialized. Call init() first.');
    }
  }

  // ============ RESERVATIONS ============

  /// Sauvegarde les reservations en cache (format JSON)
  Future<void> cacheReservationsJson(
      List<Map<String, dynamic>> reservations) async {
    _ensureInitialized();
    await _box.put(_reservationsKey, jsonEncode(reservations));
    await _updateLastSync();
  }

  /// Recupere les reservations du cache (format JSON)
  Future<List<Map<String, dynamic>>?> getCachedReservationsJson() async {
    _ensureInitialized();
    final jsonString = _box.get(_reservationsKey) as String?;
    if (jsonString == null) return null;

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarde une reservation individuelle
  Future<void> cacheReservationJson(
      String id, Map<String, dynamic> reservation) async {
    _ensureInitialized();
    await _box.put('reservation_$id', jsonEncode(reservation));
  }

  /// Recupere une reservation par ID
  Future<Map<String, dynamic>?> getCachedReservationJson(String id) async {
    _ensureInitialized();
    final jsonString = _box.get('reservation_$id') as String?;
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Supprime une reservation du cache
  Future<void> removeReservation(String id) async {
    _ensureInitialized();
    await _box.delete('reservation_$id');
  }

  // ============ VEHICLES ============

  /// Sauvegarde les vehicules en cache (format JSON)
  Future<void> cacheVehiclesJson(List<Map<String, dynamic>> vehicles) async {
    _ensureInitialized();
    await _box.put(_vehiclesKey, jsonEncode(vehicles));
  }

  /// Recupere les vehicules du cache (format JSON)
  Future<List<Map<String, dynamic>>?> getCachedVehiclesJson() async {
    _ensureInitialized();
    final jsonString = _box.get(_vehiclesKey) as String?;
    if (jsonString == null) return null;

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarde un vehicule individuel
  Future<void> cacheVehicleJson(String id, Map<String, dynamic> vehicle) async {
    _ensureInitialized();
    await _box.put('vehicle_$id', jsonEncode(vehicle));
  }

  /// Recupere un vehicule par ID
  Future<Map<String, dynamic>?> getCachedVehicleJson(String id) async {
    _ensureInitialized();
    final jsonString = _box.get('vehicle_$id') as String?;
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Supprime un vehicule du cache
  Future<void> removeVehicle(String id) async {
    _ensureInitialized();
    await _box.delete('vehicle_$id');
  }

  // ============ SYNC STATUS ============

  /// Met a jour le timestamp de derniere synchronisation
  Future<void> _updateLastSync() async {
    await _box.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Derniere synchronisation
  Future<DateTime?> getLastSync() async {
    _ensureInitialized();
    final dateString = _box.get(_lastSyncKey) as String?;
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Verifie si le cache est perime
  Future<bool> isCacheStale(
      {Duration staleDuration = const Duration(minutes: 15)}) async {
    final lastSync = await getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > staleDuration;
  }

  /// Verifie si des donnees existent en cache
  Future<bool> hasCache() async {
    _ensureInitialized();
    return _box.containsKey(_reservationsKey) || _box.containsKey(_vehiclesKey);
  }

  // ============ PENDING ACTIONS ============

  /// Ajoute une action en attente (pour sync offline)
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    _ensureInitialized();
    final actions = await getPendingActions();
    actions.add({
      ...action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _box.put(_pendingActionsKey, jsonEncode(actions));
  }

  /// Recupere les actions en attente
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    _ensureInitialized();
    final jsonString = _box.get(_pendingActionsKey) as String?;
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Supprime une action en attente
  Future<void> removePendingAction(int index) async {
    _ensureInitialized();
    final actions = await getPendingActions();
    if (index >= 0 && index < actions.length) {
      actions.removeAt(index);
      await _box.put(_pendingActionsKey, jsonEncode(actions));
    }
  }

  /// Efface toutes les actions en attente
  Future<void> clearPendingActions() async {
    _ensureInitialized();
    await _box.delete(_pendingActionsKey);
  }

  /// Nombre d'actions en attente
  Future<int> get pendingActionsCount async {
    final actions = await getPendingActions();
    return actions.length;
  }

  // ============ CLEAR ============

  /// Efface tout le cache des reservations
  Future<void> clear() async {
    _ensureInitialized();
    await _box.clear();
  }

  /// Efface uniquement les reservations (garde les vehicules)
  Future<void> clearReservations() async {
    _ensureInitialized();
    await _box.delete(_reservationsKey);
    // Supprimer aussi les reservations individuelles
    final keys =
        _box.keys.where((k) => k.toString().startsWith('reservation_'));
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Efface uniquement les vehicules
  Future<void> clearVehicles() async {
    _ensureInitialized();
    await _box.delete(_vehiclesKey);
    // Supprimer aussi les vehicules individuels
    final keys = _box.keys.where((k) => k.toString().startsWith('vehicle_'));
    for (final key in keys) {
      await _box.delete(key);
    }
  }
}
