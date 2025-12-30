import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

/// Service pour gérer les connexions WebSocket en temps réel
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String? _authToken;
  bool _isConnecting = false;

  // Stream controllers pour les différents événements
  final _reservationUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  /// Stream pour les mises à jour de réservations
  Stream<Map<String, dynamic>> get reservationUpdates => _reservationUpdatesController.stream;

  /// Stream pour les mises à jour de jobs (pour workers)
  Stream<Map<String, dynamic>> get jobUpdates => _jobUpdatesController.stream;

  /// Stream pour les notifications en temps réel
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  /// Stream pour le statut de connexion
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Vérifier si connecté
  bool get isConnected => _socket?.connected ?? false;

  /// Initialiser la connexion Socket
  Future<void> connect(String authToken) async {
    if (_isConnecting) return;
    if (_socket?.connected == true && _authToken == authToken) return;

    _isConnecting = true;
    _authToken = authToken;

    try {
      // Déconnecter si déjà connecté
      await disconnect();

      // Créer la connexion
      _socket = io.io(
        AppConfig.apiBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': authToken})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(10)
            .build(),
      );

      // Configurer les event handlers
      _setupEventHandlers();

      // Connecter
      _socket!.connect();

      debugPrint('Socket connecting to ${AppConfig.apiBaseUrl}');
    } catch (e) {
      debugPrint('Error connecting socket: $e');
      _connectionStatusController.add(false);
    } finally {
      _isConnecting = false;
    }
  }

  /// Configurer les handlers d'événements
  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
      _connectionStatusController.add(false);
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });

    // Événements de réservation
    _socket!.on('reservation:updated', (data) {
      debugPrint('Reservation updated: $data');
      _reservationUpdatesController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('reservation:cancelled', (data) {
      debugPrint('Reservation cancelled: $data');
      _reservationUpdatesController.add({
        'type': 'cancelled',
        ...Map<String, dynamic>.from(data),
      });
    });

    _socket!.on('reservation:statusChanged', (data) {
      debugPrint('Reservation status changed: $data');
      _reservationUpdatesController.add({
        'type': 'statusChanged',
        ...Map<String, dynamic>.from(data),
      });
    });

    // Événements de job (pour workers)
    _socket!.on('job:new', (data) {
      debugPrint('New job available: $data');
      _jobUpdatesController.add({
        'type': 'new',
        ...Map<String, dynamic>.from(data),
      });
    });

    _socket!.on('job:assigned', (data) {
      debugPrint('Job assigned: $data');
      _jobUpdatesController.add({
        'type': 'assigned',
        ...Map<String, dynamic>.from(data),
      });
    });

    _socket!.on('job:cancelled', (data) {
      debugPrint('Job cancelled: $data');
      _jobUpdatesController.add({
        'type': 'cancelled',
        ...Map<String, dynamic>.from(data),
      });
    });

    // Événements de notification
    _socket!.on('notification:new', (data) {
      debugPrint('New notification: $data');
      _notificationController.add(Map<String, dynamic>.from(data));
    });

    // Événement pour les workers - position du client
    _socket!.on('worker:clientLocation', (data) {
      debugPrint('Client location update: $data');
      _jobUpdatesController.add({
        'type': 'clientLocation',
        ...Map<String, dynamic>.from(data),
      });
    });
  }

  /// Émettre la position du worker
  void emitWorkerLocation(double latitude, double longitude) {
    if (!isConnected) return;

    _socket!.emit('worker:updateLocation', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Rejoindre une room de réservation spécifique
  void joinReservationRoom(String reservationId) {
    if (!isConnected) return;
    _socket!.emit('join:reservation', {'reservationId': reservationId});
  }

  /// Quitter une room de réservation
  void leaveReservationRoom(String reservationId) {
    if (!isConnected) return;
    _socket!.emit('leave:reservation', {'reservationId': reservationId});
  }

  /// Déconnecter le socket
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _authToken = null;
      debugPrint('Socket disconnected and disposed');
    }
  }

  /// Libérer les ressources
  void dispose() {
    disconnect();
    _reservationUpdatesController.close();
    _jobUpdatesController.close();
    _notificationController.close();
    _connectionStatusController.close();
  }

  /// Émettre un événement générique
  void emit(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      debugPrint('Socket not connected, cannot emit: $event');
      return;
    }
    _socket!.emit(event, data);
  }

  /// Écouter un événement générique et retourner un Stream
  Stream<dynamic> on(String event) {
    final controller = StreamController<dynamic>.broadcast();

    if (_socket != null) {
      _socket!.on(event, (data) {
        controller.add(data);
      });
    }

    return controller.stream;
  }

  /// Retirer l'écoute d'un événement
  void off(String event) {
    _socket?.off(event);
  }
}
