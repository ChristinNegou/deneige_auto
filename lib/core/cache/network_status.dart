import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Provider pour surveiller l'etat du reseau
class NetworkStatus extends ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;

  NetworkStatus({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Initialise le listener de connectivite
  Future<void> init() async {
    // Verifier le statut initial
    await checkConnection();

    // Ecouter les changements
    _subscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  /// Verifie la connexion actuelle
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    final newStatus = !results.contains(ConnectivityResult.none);

    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      notifyListeners();
    }

    return _isOnline;
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final newStatus = !results.contains(ConnectivityResult.none);

    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      notifyListeners();
    }
  }

  /// Stream des changements de connectivite
  Stream<bool> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Extension pour faciliter l'utilisation
extension NetworkStatusExtension on NetworkStatus {
  /// Execute une action si en ligne, sinon execute le fallback
  Future<T> executeOnlineOrFallback<T>({
    required Future<T> Function() onlineAction,
    required Future<T> Function() offlineFallback,
  }) async {
    if (isOnline) {
      try {
        return await onlineAction();
      } catch (e) {
        // En cas d'erreur reseau, utiliser le fallback
        return offlineFallback();
      }
    }
    return offlineFallback();
  }
}
