import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion de la connectivité réseau
/// Permet de surveiller l'état de la connexion et de mettre en cache les requêtes hors-ligne
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream de l'état de connexion
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// État actuel de la connexion
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// File d'attente des opérations hors-ligne
  final List<PendingOperation> _pendingOperations = [];
  List<PendingOperation> get pendingOperations => List.unmodifiable(_pendingOperations);

  /// Initialise le service de connectivité
  Future<void> initialize() async {
    // Vérifier l'état initial
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Écouter les changements
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (_isConnected != wasConnected) {
      _connectionStatusController.add(_isConnected);

      if (_isConnected && _pendingOperations.isNotEmpty) {
        // Exécuter les opérations en attente quand la connexion revient
        _processPendingOperations();
      }
    }

    if (kDebugMode) {
      print('Connectivity status: $_isConnected (results: $results)');
    }
  }

  /// Vérifie si le réseau est disponible
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return _isConnected;
  }

  /// Ajoute une opération à la file d'attente hors-ligne
  void addPendingOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
    if (kDebugMode) {
      print('Added pending operation: ${operation.type} - ${_pendingOperations.length} in queue');
    }
  }

  /// Traite les opérations en attente
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    if (kDebugMode) {
      print('Processing ${_pendingOperations.length} pending operations...');
    }

    final operationsToProcess = List<PendingOperation>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operationsToProcess) {
      try {
        await operation.execute();
        if (kDebugMode) {
          print('Successfully executed pending operation: ${operation.type}');
        }
      } catch (e) {
        // En cas d'échec, remettre dans la file si l'opération peut être réessayée
        if (operation.canRetry && operation.retryCount < operation.maxRetries) {
          operation.retryCount++;
          _pendingOperations.add(operation);
          if (kDebugMode) {
            print('Re-queued failed operation: ${operation.type} (attempt ${operation.retryCount})');
          }
        } else {
          if (kDebugMode) {
            print('Failed to execute operation after max retries: ${operation.type}');
          }
        }
      }
    }
  }

  /// Annule une opération en attente
  void cancelPendingOperation(String operationId) {
    _pendingOperations.removeWhere((op) => op.id == operationId);
  }

  /// Efface toutes les opérations en attente
  void clearPendingOperations() {
    _pendingOperations.clear();
  }

  /// Dispose du service
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}

/// Représente une opération en attente de synchronisation
class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final Future<void> Function() execute;
  final bool canRetry;
  final int maxRetries;
  int retryCount;
  final DateTime createdAt;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.execute,
    this.canRetry = true,
    this.maxRetries = 3,
    this.retryCount = 0,
  }) : createdAt = DateTime.now();

  @override
  String toString() => 'PendingOperation($type, retries: $retryCount/$maxRetries)';
}

/// Extension pour faciliter l'ajout d'opérations
extension ConnectivityServiceExtension on ConnectivityService {
  /// Exécute une opération ou la met en file d'attente si hors-ligne
  Future<T?> executeOrQueue<T>({
    required String operationId,
    required String operationType,
    required Map<String, dynamic> data,
    required Future<T> Function() onlineOperation,
    T? Function()? offlineValue,
    bool canRetry = true,
  }) async {
    if (isConnected) {
      return await onlineOperation();
    } else {
      addPendingOperation(
        PendingOperation(
          id: operationId,
          type: operationType,
          data: data,
          execute: () async {
            await onlineOperation();
          },
          canRetry: canRetry,
        ),
      );
      return offlineValue?.call();
    }
  }
}
