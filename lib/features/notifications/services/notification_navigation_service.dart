import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/di/injection_container.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../chat/presentation/bloc/chat_bloc.dart';
import '../../chat/presentation/pages/chat_screen.dart';
import '../domain/entities/notification.dart';

/// Service de navigation basé sur les notifications
/// Implémente le deep-linking moderne comme les apps Uber, DoorDash, etc.
class NotificationNavigationService {
  static final NotificationNavigationService _instance = NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigue vers l'écran approprié selon le type de notification
  Future<void> handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    // Traitement spécial pour les notifications de chat
    if (notification.type == NotificationType.newMessage ||
        notification.type == NotificationType.workerMessage) {
      _navigateToChat(context, notification);
      return;
    }

    final route = _getRouteForNotification(notification);
    final arguments = _getArgumentsForNotification(notification);

    if (route == null) return;

    // Vérifier si on a besoin d'un reservationId mais qu'il est null
    if (_routeRequiresReservationId(route) &&
        (notification.reservationId == null || notification.reservationId!.isEmpty)) {
      // Fallback vers la liste des réservations
      Navigator.of(context).pushNamed(AppRoutes.reservations);
      return;
    }

    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  /// Navigation vers le chat pour les notifications de message
  void _navigateToChat(BuildContext context, AppNotification notification) {
    if (notification.reservationId == null || notification.reservationId!.isEmpty) {
      // Fallback vers les réservations si pas de reservationId
      Navigator.of(context).pushNamed(AppRoutes.reservations);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non authentifié'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Extraire le nom de l'expéditeur depuis les metadata ou le message
    String otherUserName = 'Utilisateur';
    if (notification.metadata != null) {
      otherUserName = notification.metadata!['senderName'] as String? ??
                      notification.metadata!['workerName'] as String? ??
                      'Utilisateur';
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ChatBloc>()..add(LoadMessages(notification.reservationId!)),
          child: ChatScreen(
            reservationId: notification.reservationId!,
            otherUserName: otherUserName,
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
        ),
      ),
    );
  }

  /// Vérifie si une route nécessite un reservationId
  bool _routeRequiresReservationId(String route) {
    return route == AppRoutes.reservationDetails;
  }

  /// Détermine la route selon le type de notification
  String? _getRouteForNotification(AppNotification notification) {
    switch (notification.type) {
      // Notifications liées aux réservations - vers les détails de la réservation
      case NotificationType.reservationAssigned:
      case NotificationType.workerEnRoute:
      case NotificationType.workStarted:
      case NotificationType.workCompleted:
        return notification.reservationId != null
            ? AppRoutes.reservationDetails
            : AppRoutes.reservations;

      // Notifications de paiement
      case NotificationType.paymentSuccess:
      case NotificationType.paymentFailed:
      case NotificationType.refundProcessed:
        return AppRoutes.payments;

      // Annulation
      case NotificationType.reservationCancelled:
        return AppRoutes.reservations;

      // Alertes météo - vers la page météo ou home
      case NotificationType.weatherAlert:
        return AppRoutes.weather;

      // Demandes urgentes (pour workers)
      case NotificationType.urgentRequest:
        return AppRoutes.jobsList;

      // Messages - géré directement par _navigateToChat
      case NotificationType.workerMessage:
      case NotificationType.newMessage:
        return null; // Navigation gérée par _navigateToChat

      // Pourboire et évaluation - vers les détails de la réservation
      case NotificationType.tipReceived:
      case NotificationType.rating:
        return notification.reservationId != null
            ? AppRoutes.reservationDetails
            : null;

      // Système
      case NotificationType.systemNotification:
        return null; // Reste sur la page actuelle
    }
  }

  /// Construit les arguments de navigation
  /// Retourne le reservationId directement car c'est ce qu'attend ReservationDetailsPage
  dynamic _getArgumentsForNotification(AppNotification notification) {
    // Pour les pages qui attendent un reservationId directement
    if (notification.reservationId != null) {
      final route = _getRouteForNotification(notification);
      if (route == AppRoutes.reservationDetails) {
        return notification.reservationId;
      }
    }

    // Pour les autres pages, pas d'arguments nécessaires
    return null;
  }

  /// Obtient le call-to-action approprié pour une notification
  NotificationAction? getActionForNotification(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.reservationAssigned:
        return NotificationAction(
          label: 'Voir les détails',
          icon: Icons.visibility,
          route: AppRoutes.reservationDetails,
        );

      case NotificationType.workerEnRoute:
        return NotificationAction(
          label: 'Suivre la réservation',
          icon: Icons.location_on,
          route: AppRoutes.reservationDetails,
          isHighlighted: true,
        );

      case NotificationType.workStarted:
        return NotificationAction(
          label: 'Voir la progression',
          icon: Icons.timer,
          route: AppRoutes.reservationDetails,
        );

      case NotificationType.workCompleted:
        return NotificationAction(
          label: 'Voir les détails',
          icon: Icons.check_circle,
          route: AppRoutes.reservationDetails,
          isHighlighted: true,
        );

      case NotificationType.paymentFailed:
        return NotificationAction(
          label: 'Gérer les paiements',
          icon: Icons.payment,
          route: AppRoutes.payments,
          isHighlighted: true,
          isUrgent: true,
        );

      case NotificationType.paymentSuccess:
        return NotificationAction(
          label: 'Voir l\'historique',
          icon: Icons.receipt,
          route: AppRoutes.payments,
        );

      case NotificationType.refundProcessed:
        return NotificationAction(
          label: 'Voir les détails',
          icon: Icons.info,
          route: AppRoutes.payments,
        );

      case NotificationType.reservationCancelled:
        return NotificationAction(
          label: 'Nouvelle réservation',
          icon: Icons.add,
          route: AppRoutes.newReservation,
        );

      case NotificationType.weatherAlert:
        return NotificationAction(
          label: 'Réserver maintenant',
          icon: Icons.ac_unit,
          route: AppRoutes.newReservation,
          isHighlighted: true,
        );

      case NotificationType.urgentRequest:
        return NotificationAction(
          label: 'Voir les jobs',
          icon: Icons.priority_high,
          route: AppRoutes.jobsList,
          isUrgent: true,
        );

      case NotificationType.workerMessage:
        return NotificationAction(
          label: 'Ouvrir le chat',
          icon: Icons.chat_bubble_rounded,
          route: '', // Géré par _navigateToChat
          isHighlighted: true,
        );

      case NotificationType.newMessage:
        return NotificationAction(
          label: 'Répondre',
          icon: Icons.chat_bubble_rounded,
          route: '', // Géré par _navigateToChat
          isHighlighted: true,
        );

      case NotificationType.tipReceived:
        return NotificationAction(
          label: 'Voir les détails',
          icon: Icons.attach_money_rounded,
          route: AppRoutes.reservationDetails,
          isHighlighted: true,
        );

      case NotificationType.rating:
        return NotificationAction(
          label: 'Voir l\'évaluation',
          icon: Icons.star_rounded,
          route: AppRoutes.reservationDetails,
        );

      case NotificationType.systemNotification:
        return null;
    }
  }
}

/// Action associée à une notification (CTA)
class NotificationAction {
  final String label;
  final IconData icon;
  final String route;
  final bool isHighlighted;
  final bool isUrgent;

  const NotificationAction({
    required this.label,
    required this.icon,
    required this.route,
    this.isHighlighted = false,
    this.isUrgent = false,
  });
}
