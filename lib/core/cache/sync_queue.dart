import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Types d'operations pour la queue de synchronisation
enum SyncOperationType {
  createReservation,
  cancelReservation,
  updateReservation,
  addVehicle,
  deleteVehicle,
  updateProfile,
}

/// Element de la queue de synchronisation
class SyncQueueItem {
  final String id;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  SyncQueueItem copyWith({
    int? retryCount,
    String? error,
  }) {
    return SyncQueueItem(
      id: id,
      type: type,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  static SyncOperationType _parseType(String type) {
    switch (type) {
      case 'createReservation':
        return SyncOperationType.createReservation;
      case 'cancelReservation':
        return SyncOperationType.cancelReservation;
      case 'updateReservation':
        return SyncOperationType.updateReservation;
      case 'addVehicle':
        return SyncOperationType.addVehicle;
      case 'deleteVehicle':
        return SyncOperationType.deleteVehicle;
      case 'updateProfile':
        return SyncOperationType.updateProfile;
      default:
        throw ArgumentError('Unknown SyncOperationType: $type');
    }
  }
}

/// Queue de synchronisation pour les operations offline
class SyncQueue {
  static const String _boxName = 'sync_queue';
  static const String _queueKey = 'pending_operations';
  static const int maxRetries = 3;

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
      throw StateError('SyncQueue not initialized. Call init() first.');
    }
  }

  /// Ajoute une operation a la queue
  Future<void> enqueue(SyncQueueItem item) async {
    _ensureInitialized();
    final items = await getAll();
    items.add(item);
    await _saveAll(items);
  }

  /// Cree et ajoute une nouvelle operation
  Future<void> addOperation(
      SyncOperationType type, Map<String, dynamic> data) async {
    final item = SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    await enqueue(item);
  }

  /// Recupere toutes les operations en attente
  Future<List<SyncQueueItem>> getAll() async {
    _ensureInitialized();
    final jsonString = _box.get(_queueKey) as String?;
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SyncQueueItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Recupere les operations en attente par type
  Future<List<SyncQueueItem>> getByType(SyncOperationType type) async {
    final all = await getAll();
    return all.where((item) => item.type == type).toList();
  }

  /// Nombre d'operations en attente
  Future<int> get pendingCount async {
    final items = await getAll();
    return items.length;
  }

  /// Verifie s'il y a des operations en attente
  Future<bool> get hasPending async {
    return await pendingCount > 0;
  }

  /// Supprime une operation de la queue
  Future<void> remove(String id) async {
    _ensureInitialized();
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _saveAll(items);
  }

  /// Marque une operation comme echouee et incremente le retry
  Future<bool> markFailed(String id, String error) async {
    _ensureInitialized();
    final items = await getAll();
    final index = items.indexWhere((item) => item.id == id);

    if (index == -1) return false;

    final item = items[index];
    final newRetryCount = item.retryCount + 1;

    if (newRetryCount >= maxRetries) {
      // Supprimer apres max retries
      items.removeAt(index);
      await _saveAll(items);
      return false;
    }

    items[index] = item.copyWith(
      retryCount: newRetryCount,
      error: error,
    );
    await _saveAll(items);
    return true;
  }

  /// Efface toute la queue
  Future<void> clear() async {
    _ensureInitialized();
    await _box.delete(_queueKey);
  }

  /// Recupere la prochaine operation a traiter
  Future<SyncQueueItem?> peek() async {
    final items = await getAll();
    return items.isEmpty ? null : items.first;
  }

  /// Traite et supprime la premiere operation
  Future<SyncQueueItem?> dequeue() async {
    final items = await getAll();
    if (items.isEmpty) return null;

    final item = items.removeAt(0);
    await _saveAll(items);
    return item;
  }

  Future<void> _saveAll(List<SyncQueueItem> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _box.put(_queueKey, jsonEncode(jsonList));
  }
}
