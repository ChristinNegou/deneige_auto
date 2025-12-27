/// Deneige-Auto Notifications Module
///
/// Ce module fournit un système de notifications complet inspiré des applications modernes
/// comme Uber, DoorDash, etc.
///
/// ## Fonctionnalités principales:
/// - Notifications en temps réel via polling adaptatif
/// - Deep-linking vers les écrans appropriés
/// - Préférences utilisateur (mode silencieux, catégories, etc.)
/// - Bannières in-app pour les nouvelles notifications
/// - Badges de notification avec animations
///
/// ## Utilisation:
///
/// ```dart
/// // Initialiser le polling
/// final pollingService = NotificationPollingService();
/// pollingService.initialize(
///   getNotifications: sl<GetNotificationsUseCase>(),
///   getUnreadCount: sl<GetUnreadCountUseCase>(),
/// );
/// pollingService.startPolling();
///
/// // Afficher une bannière
/// NotificationBannerManager().show(context, notification);
///
/// // Badge avec compteur automatique
/// AutoNotificationBadge(
///   child: Icon(Icons.notifications),
/// )
/// ```
library notifications;

// Domain
export 'domain/entities/notification.dart';
export 'domain/repositories/notification_repository.dart';
export 'domain/usecases/get_notifications_usecase.dart';
export 'domain/usecases/get_unread_count_usecase.dart';
export 'domain/usecases/mark_as_read_usecase.dart';
export 'domain/usecases/mark_all_as_read_usecase.dart';
export 'domain/usecases/delete_notification_usecase.dart';
export 'domain/usecases/clear_all_notifications_usecase.dart';

// Data
export 'data/models/notification_model.dart';
export 'data/datasources/notification_remote_datasource.dart';
export 'data/repositories/notification_repository_impl.dart';

// Presentation - BLoC
export 'presentation/bloc/notification_bloc.dart';

// Presentation - Pages
export 'presentation/pages/notifications_page.dart';
export 'presentation/pages/notification_settings_page.dart';

// Presentation - Widgets
export 'presentation/widgets/notification_banner.dart';
export 'presentation/widgets/notification_badge.dart';

// Services
export 'services/notification_navigation_service.dart';
export 'services/notification_polling_service.dart';
export 'services/notification_preferences_service.dart';
