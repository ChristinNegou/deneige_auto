import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../di/injection_container.dart';

/// Handler pour les messages en arrière-plan (doit être une fonction top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

/// Service de notifications push via Firebase Cloud Messaging (FCM).
/// Gère les permissions, l'affichage local, les tokens et les topics.
class PushNotificationService {
  // --- Singleton ---

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // --- Dépendances ---

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- État interne ---

  bool _isInitialized = false;
  String? _fcmToken;

  // StreamSubscriptions pour éviter les fuites de mémoire
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  /// Token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Callback pour gérer les clics sur les notifications
  void Function(Map<String, dynamic> data)? onNotificationTap;

  // --- Initialisation ---

  /// Initialise le service de notifications.
  /// Configure Firebase, les permissions, les notifications locales et les handlers.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser Firebase (si pas déjà fait)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Configurer le handler pour les messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Demander les permissions
      await _requestPermissions();

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Configurer les handlers de messages
      _setupMessageHandlers();

      // Obtenir le token FCM
      await _getToken();

      // Écouter les mises à jour du token
      _tokenRefreshSubscription =
          _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;
      debugPrint('Push notification service initialized');
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  // --- Permissions ---

  /// Demande les permissions de notification à l'utilisateur.
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
      carPlay: false,
    );

    debugPrint(
        'Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('User denied notification permissions');
    }
  }

  // --- Notifications locales ---

  /// Initialise les notifications locales (Android et iOS).
  /// Crée le canal de notification Android avec son, vibration et haute priorité.
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'deneige_notifications',
        'Notifications Deneige Auto',
        description: 'Notifications pour l\'application Deneige Auto',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // --- Handlers de messages ---

  /// Configure les handlers de messages Firebase.
  /// Gère les messages au premier plan, en arrière-plan et au lancement.
  void _setupMessageHandlers() {
    // Message reçu quand l'app est au premier plan
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message ouvert depuis la notification (app en arrière-plan)
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Vérifier si l'app a été ouverte depuis une notification
    _checkInitialMessage();
  }

  /// Vérifier si l'app a été lancée depuis une notification
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  /// Gérer un message au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // Afficher une notification locale
    await _showLocalNotification(message);
  }

  /// Gérer l'ouverture d'une notification
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.data}');

    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }

  /// Gérer la réponse à une notification locale
  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('Local notification response: ${response.payload}');

    if (response.payload != null && onNotificationTap != null) {
      try {
        final data = jsonDecode(response.payload!);
        onNotificationTap!(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Affiche une notification locale à partir d'un message Firebase.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'deneige_notifications',
      'Notifications Deneige Auto',
      channelDescription: 'Notifications pour l\'application Deneige Auto',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // --- Gestion du token FCM ---

  /// Obtient le token FCM de l'appareil.
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Gérer le rafraîchissement du token
  void _handleTokenRefresh(String token) {
    debugPrint('FCM Token refreshed: $token');
    _fcmToken = token;
    // Enregistrer le nouveau token sur le serveur
    registerTokenOnServer(token);
  }

  /// Enregistre le token FCM sur le serveur backend.
  /// Utilisé lors de l'initialisation et du rafraîchissement automatique.
  Future<bool> registerTokenOnServer([String? token]) async {
    final tokenToRegister = token ?? _fcmToken;
    if (tokenToRegister == null) {
      debugPrint('No FCM token to register');
      return false;
    }

    try {
      final dio = sl<Dio>();
      await dio.post('/notifications/register-token', data: {
        'fcmToken': tokenToRegister,
      });
      debugPrint('FCM token registered on server');
      return true;
    } catch (e) {
      debugPrint('Error registering FCM token on server: $e');
      return false;
    }
  }

  /// Supprimer le token FCM du serveur (lors de la déconnexion)
  Future<bool> unregisterTokenFromServer() async {
    try {
      final dio = sl<Dio>();
      await dio.delete('/notifications/unregister-token');
      debugPrint('FCM token unregistered from server');
      return true;
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
      return false;
    }
  }

  // --- Gestion des topics ---

  /// S'abonne à un topic FCM pour recevoir des notifications groupées.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // --- Utilitaires ---

  /// Retourne le statut actuel des permissions de notification.
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  // --- Nettoyage ---

  /// Libère les ressources du service (subscriptions et état).
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _messageOpenedSubscription = null;
    _isInitialized = false;
    debugPrint('Push notification service disposed');
  }
}
