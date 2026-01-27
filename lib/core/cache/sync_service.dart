import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_queue.dart';

/// Callback pour traiter une opération de synchronisation.
typedef SyncOperationHandler = Future<bool> Function(SyncQueueItem item);

/// Service de synchronisation automatique des opérations hors-ligne.
/// Surveille la connectivité et traite périodiquement la file d'attente.
class SyncService {
  // --- Dépendances ---

  final SyncQueue _queue;
  final Connectivity _connectivity;
  final Map<SyncOperationType, SyncOperationHandler> _handlers = {};

  // --- État interne ---

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // --- Configuration ---

  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 30);

  SyncService({
    SyncQueue? queue,
    Connectivity? connectivity,
  })  : _queue = queue ?? SyncQueue(),
        _connectivity = connectivity ?? Connectivity();

  // --- Initialisation ---

  /// Initialise la queue, l'écoute réseau et la synchronisation périodique.
  Future<void> init() async {
    await _queue.init();
    _startConnectivityListener();
    _startPeriodicSync();
  }

  // --- Enregistrement des handlers ---

  /// Enregistre un handler pour un type d'opération donné.
  void registerHandler(SyncOperationType type, SyncOperationHandler handler) {
    _handlers[type] = handler;
  }

  // --- Ajout d'opérations ---

  /// Ajoute une opération à la queue et tente une synchronisation immédiate si en ligne.
  Future<void> addOperation(
      SyncOperationType type, Map<String, dynamic> data) async {
    await _queue.addOperation(type, data);

    // Tente de synchroniser immediatement si en ligne
    if (await _isOnline()) {
      _triggerSync();
    }
  }

  // --- Écoute réseau et synchronisation périodique ---

  /// Démarre l'écoute de la connectivité pour synchroniser au retour du réseau.
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final isOnline = !results.contains(ConnectivityResult.none);
        if (isOnline) {
          _triggerSync();
        }
      },
    );
  }

  /// Démarre la synchronisation périodique selon [syncInterval].
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(syncInterval, (_) {
      _triggerSync();
    });
  }

  /// Déclenche une synchronisation si aucune n'est en cours.
  void _triggerSync() {
    if (!_isSyncing) {
      _syncAll();
    }
  }

  // --- Logique de synchronisation ---

  /// Synchronise toutes les opérations en attente une par une.
  /// Gère les erreurs et les retries via la queue.
  Future<SyncResult> _syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Synchronisation deja en cours',
        processedCount: 0,
        failedCount: 0,
      );
    }

    _isSyncing = true;
    int processedCount = 0;
    int failedCount = 0;

    try {
      if (!await _isOnline()) {
        return SyncResult(
          success: false,
          message: 'Pas de connexion internet',
          processedCount: 0,
          failedCount: 0,
        );
      }

      while (await _queue.hasPending) {
        final item = await _queue.peek();
        if (item == null) break;

        final handler = _handlers[item.type];
        if (handler == null) {
          // Pas de handler, supprimer l'operation
          await _queue.remove(item.id);
          continue;
        }

        try {
          final success = await handler(item);
          if (success) {
            await _queue.remove(item.id);
            processedCount++;
          } else {
            final shouldRetry =
                await _queue.markFailed(item.id, 'Operation echouee');
            if (!shouldRetry) {
              failedCount++;
            }
          }
        } catch (e) {
          final shouldRetry = await _queue.markFailed(item.id, e.toString());
          if (!shouldRetry) {
            failedCount++;
          }
        }
      }

      return SyncResult(
        success: true,
        message: 'Synchronisation terminee',
        processedCount: processedCount,
        failedCount: failedCount,
      );
    } finally {
      _isSyncing = false;
    }
  }

  // --- API publique ---

  /// Lance manuellement la synchronisation de toutes les opérations en attente.
  Future<SyncResult> syncNow() async {
    return _syncAll();
  }

  /// Vérifie si l'appareil dispose d'une connexion internet.
  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Nombre d'operations en attente
  Future<int> get pendingCount => _queue.pendingCount;

  /// Verifie s'il y a des operations en attente
  Future<bool> get hasPendingOperations => _queue.hasPending;

  // --- Nettoyage ---

  /// Arrête le service (subscription réseau et timer périodique).
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}

/// Résultat d'une synchronisation.
/// Contient le nombre d'opérations traitées, échouées et le message de statut.
class SyncResult {
  final bool success;
  final String message;
  final int processedCount;
  final int failedCount;

  const SyncResult({
    required this.success,
    required this.message,
    required this.processedCount,
    required this.failedCount,
  });

  int get totalCount => processedCount + failedCount;
}
