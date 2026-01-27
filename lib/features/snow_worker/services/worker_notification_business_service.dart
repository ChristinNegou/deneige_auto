import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../domain/entities/worker_job.dart';
import 'worker_notification_service.dart';
import '../../../l10n/app_localizations.dart';

/// Types de notifications spécifiques aux snowworkers
enum WorkerNotificationType {
  // Jobs
  newJobAvailable, // Nouveau job disponible
  jobAssigned, // Job assigné au worker
  jobCancelled, // Job annulé par le client
  jobModified, // Job modifié par le client

  // Revenus
  paymentReceived, // Paiement reçu
  bonusEarned, // Bonus gagné
  weeklyPayoutReady, // Paiement hebdomadaire prêt

  // Performance
  ratingReceived, // Nouvelle évaluation reçue
  performanceAlert, // Alerte de performance (taux annulation élevé)
  milestoneReached, // Jalon atteint (100 jobs, etc.)

  // Système
  documentExpiring, // Document expirant bientôt
  accountUpdate, // Mise à jour du compte
  zoneHighDemand, // Zone à forte demande
  weatherOpportunity, // Opportunité météo (tempête prévue)
}

/// Service de logique métier pour les notifications des snowworkers
class WorkerNotificationBusinessService {
  static final WorkerNotificationBusinessService _instance =
      WorkerNotificationBusinessService._internal();
  factory WorkerNotificationBusinessService() => _instance;
  WorkerNotificationBusinessService._internal();

  final WorkerNotificationService _localNotificationService =
      WorkerNotificationService();
  Dio? _dio;

  // Stream pour les notifications en temps réel
  final StreamController<WorkerNotificationEvent> _eventController =
      StreamController<WorkerNotificationEvent>.broadcast();
  Stream<WorkerNotificationEvent> get events => _eventController.stream;

  // Cache des jobs récemment notifiés pour éviter les doublons
  final Set<String> _notifiedJobIds = {};
  static const int _maxCacheSize = 100;

  /// Initialise le service avec le client Dio
  Future<void> initialize(Dio dio) async {
    _dio = dio;
    await _localNotificationService.initialize();
  }

  // ===== Notifications de Jobs =====

  /// Notifie d'un nouveau job disponible
  Future<void> notifyNewJobAvailable(WorkerJob job,
      {AppLocalizations? l10n}) async {
    // Éviter les doublons
    if (_notifiedJobIds.contains(job.id)) return;
    _addToCache(job.id);

    await _localNotificationService.notifyNewJob(job);

    _emitEvent(
      WorkerNotificationType.newJobAvailable,
      title: job.isPriority
          ? (l10n?.worker_notifUrgentJob ?? 'Job Urgent!')
          : (l10n?.worker_newJob ?? 'Nouveau job'),
      message: '${job.displayAddress} - ${job.totalPrice.toStringAsFixed(2)}\$',
      data: {'jobId': job.id, 'isPriority': job.isPriority},
    );

    debugPrint('[WorkerNotification] New job available: ${job.id}');
  }

  /// Notifie de plusieurs nouveaux jobs
  Future<void> notifyMultipleJobsAvailable(
    List<WorkerJob> jobs, {
    bool hasUrgent = false,
    AppLocalizations? l10n,
  }) async {
    final newJobs = jobs.where((j) => !_notifiedJobIds.contains(j.id)).toList();
    if (newJobs.isEmpty) return;

    for (final job in newJobs) {
      _addToCache(job.id);
    }

    await _localNotificationService.notifyMultipleNewJobs(
      newJobs.length,
      hasUrgent: hasUrgent,
    );

    _emitEvent(
      WorkerNotificationType.newJobAvailable,
      title: l10n?.worker_businessNewJobsCount(newJobs.length) ??
          '${newJobs.length} nouveaux jobs',
      message: hasUrgent
          ? (l10n?.worker_businessIncludingUrgent ?? 'Dont des jobs urgents!')
          : (l10n?.worker_businessNearYou ?? 'Disponibles près de vous'),
      data: {'count': newJobs.length, 'hasUrgent': hasUrgent},
    );
  }

  /// Notifie quand un job est assigné au worker
  Future<void> notifyJobAssigned(WorkerJob job,
      {AppLocalizations? l10n}) async {
    await _localNotificationService.notifyJobAccepted(job);

    _emitEvent(
      WorkerNotificationType.jobAssigned,
      title: l10n?.worker_businessJobConfirmed ?? 'Job confirmé!',
      message: l10n?.worker_notifGoTo(job.displayAddress) ??
          'Rendez-vous à ${job.displayAddress}',
      data: {'jobId': job.id},
    );
  }

  /// Notifie quand un job est annulé par le client
  Future<void> notifyJobCancelled(WorkerJob job, String? reason,
      {AppLocalizations? l10n}) async {
    final notifTitle = l10n?.worker_businessJobCancelled ?? 'Job annulé';
    final notifBody = reason != null
        ? (l10n?.worker_businessJobCancelledReason(
                job.displayAddress, reason) ??
            'Le job à ${job.displayAddress} a été annulé: $reason')
        : (l10n?.worker_businessJobCancelledBody(job.displayAddress) ??
            'Le job à ${job.displayAddress} a été annulé');

    await _showLocalNotification(
      title: notifTitle,
      body: notifBody,
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.jobCancelled,
      title: notifTitle,
      message: job.displayAddress,
      data: {'jobId': job.id, 'reason': reason},
    );
  }

  /// Notifie quand un job est modifié
  Future<void> notifyJobModified(WorkerJob job, String modification,
      {AppLocalizations? l10n}) async {
    final notifTitle = l10n?.worker_businessJobModified ?? 'Job modifié';

    await _showLocalNotification(
      title: notifTitle,
      body: '$modification - ${job.displayAddress}',
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.jobModified,
      title: notifTitle,
      message: modification,
      data: {'jobId': job.id, 'modification': modification},
    );
  }

  // ===== Notifications de Revenus =====

  /// Notifie d'un paiement reçu
  Future<void> notifyPaymentReceived(double amount, String jobDescription,
      {AppLocalizations? l10n}) async {
    await _localNotificationService.notifyJobCompleted(amount);

    _emitEvent(
      WorkerNotificationType.paymentReceived,
      title: l10n?.worker_businessPaymentReceived ?? 'Paiement reçu!',
      message: l10n?.worker_businessPaymentAmount(
              amount.toStringAsFixed(2), jobDescription) ??
          '${amount.toStringAsFixed(2)}\$ pour $jobDescription',
      data: {'amount': amount},
    );
  }

  /// Notifie d'un bonus gagné
  Future<void> notifyBonusEarned(double amount, String reason,
      {AppLocalizations? l10n}) async {
    await _showLocalNotification(
      title: l10n?.worker_businessBonusEarned ?? '🎁 Bonus gagné!',
      body: l10n?.worker_businessBonusBody(amount.toStringAsFixed(2), reason) ??
          '+${amount.toStringAsFixed(2)}\$ - $reason',
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.bonusEarned,
      title: l10n?.worker_businessBonusTitle ?? 'Bonus gagné!',
      message: reason,
      data: {'amount': amount, 'reason': reason},
    );
  }

  /// Notifie que le paiement hebdomadaire est prêt
  Future<void> notifyWeeklyPayoutReady(double amount,
      {AppLocalizations? l10n}) async {
    await _showLocalNotification(
      title: l10n?.worker_businessWeeklyPayout ?? '💰 Paiement prêt!',
      body: l10n?.worker_businessWeeklyPayoutBody(amount.toStringAsFixed(2)) ??
          'Votre paiement de ${amount.toStringAsFixed(2)}\$ est disponible',
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.weeklyPayoutReady,
      title: l10n?.worker_businessPayoutAvailable ?? 'Paiement disponible',
      message: '${amount.toStringAsFixed(2)}\$',
      data: {'amount': amount},
    );
  }

  // ===== Notifications de Performance =====

  /// Notifie d'une nouvelle évaluation
  Future<void> notifyRatingReceived(int rating, String? comment,
      {AppLocalizations? l10n}) async {
    final stars = '⭐' * rating;
    await _showLocalNotification(
      title: l10n?.worker_businessNewRating ?? 'Nouvelle évaluation!',
      body: '$stars${comment != null ? ' - "$comment"' : ''}',
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.ratingReceived,
      title: l10n?.worker_businessRatingReceived ?? 'Évaluation reçue',
      message: l10n?.worker_businessRatingStars(rating) ?? '$rating étoiles',
      data: {'rating': rating, 'comment': comment},
    );
  }

  /// Notifie d'une alerte de performance
  Future<void> notifyPerformanceAlert(String issue, String suggestion,
      {AppLocalizations? l10n}) async {
    await _showLocalNotification(
      title: l10n?.worker_businessPerformanceAlert ?? '⚠️ Attention!',
      body: '$issue\n$suggestion',
      isUrgent: true,
    );

    _emitEvent(
      WorkerNotificationType.performanceAlert,
      title: l10n?.worker_businessPerformanceTitle ?? 'Alerte performance',
      message: issue,
      data: {'issue': issue, 'suggestion': suggestion},
    );
  }

  /// Notifie d'un jalon atteint
  Future<void> notifyMilestoneReached(String milestone, String? reward,
      {AppLocalizations? l10n}) async {
    await _showLocalNotification(
      title: l10n?.worker_businessMilestone ?? '🏆 Félicitations!',
      body: '$milestone${reward != null ? '\nRécompense: $reward' : ''}',
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.milestoneReached,
      title: milestone,
      message:
          reward ?? (l10n?.worker_businessKeepGoing ?? 'Continuez comme ça!'),
      data: {'milestone': milestone, 'reward': reward},
    );
  }

  // ===== Notifications Système =====

  /// Notifie qu'un document expire bientôt
  Future<void> notifyDocumentExpiring(String documentType, int daysLeft,
      {AppLocalizations? l10n}) async {
    await _showLocalNotification(
      title: l10n?.worker_businessDocExpiring ?? '📄 Document expirant',
      body: l10n?.worker_businessDocExpiringBody(documentType, daysLeft) ??
          'Votre $documentType expire dans $daysLeft jours',
      isUrgent: daysLeft <= 7,
    );

    _emitEvent(
      WorkerNotificationType.documentExpiring,
      title: l10n?.worker_businessDocExpiringTitle ?? 'Document expirant',
      message: l10n?.worker_businessDocExpiringShort(documentType, daysLeft) ??
          '$documentType - $daysLeft jours',
      data: {'documentType': documentType, 'daysLeft': daysLeft},
    );
  }

  /// Notifie d'une zone à forte demande
  Future<void> notifyHighDemandZone(String zoneName, double multiplier,
      {AppLocalizations? l10n}) async {
    final multiplierStr = multiplier.toString();
    await _showLocalNotification(
      title: l10n?.worker_businessHighDemand ?? '📈 Zone en demande!',
      body: l10n?.worker_businessHighDemandBody(zoneName, multiplierStr) ??
          '$zoneName - ${multiplier}x les gains!',
      isUrgent: false,
    );

    _emitEvent(
      WorkerNotificationType.zoneHighDemand,
      title: l10n?.worker_businessHighDemandTitle ?? 'Zone en demande',
      message: l10n?.worker_businessHighDemandShort(zoneName, multiplierStr) ??
          '$zoneName - ${multiplier}x',
      data: {'zone': zoneName, 'multiplier': multiplier},
    );
  }

  /// Notifie d'une opportunité météo
  Future<void> notifyWeatherOpportunity(
    String forecast,
    int expectedJobs,
    DateTime date, {
    AppLocalizations? l10n,
  }) async {
    await _showLocalNotification(
      title: l10n?.worker_businessWeatherAlert ?? '❄️ Tempête prévue!',
      body: l10n?.worker_businessWeatherBody(forecast, expectedJobs) ??
          '$forecast - Environ $expectedJobs jobs attendus',
      isUrgent: true,
    );

    _emitEvent(
      WorkerNotificationType.weatherOpportunity,
      title: l10n?.worker_businessWeatherTitle ?? 'Opportunité météo',
      message: forecast,
      data: {
        'forecast': forecast,
        'expectedJobs': expectedJobs,
        'date': date.toIso8601String(),
      },
    );
  }

  // ===== Envoi de notification au client =====

  /// Envoie une notification au client d'un job
  Future<bool> sendNotificationToClient({
    required String reservationId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    if (_dio == null) {
      debugPrint('[WorkerNotification] Dio not initialized');
      return false;
    }

    try {
      final response = await _dio!.post(
        '/api/notifications/send-to-client',
        data: {
          'reservationId': reservationId,
          'type': type,
          'title': title,
          'message': message,
          'metadata': metadata,
        },
      );

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('[WorkerNotification] Error sending to client: $e');
      return false;
    }
  }

  /// Notifie le client que le worker est en route
  Future<bool> notifyClientEnRoute(String reservationId, int etaMinutes,
      {AppLocalizations? l10n}) async {
    return sendNotificationToClient(
      reservationId: reservationId,
      type: 'workerEnRoute',
      title: l10n?.worker_businessClientEnRoute ?? 'Déneigeur en route!',
      message: l10n?.worker_businessClientEta(etaMinutes) ??
          'Arrivée estimée dans $etaMinutes minutes',
      metadata: {'etaMinutes': etaMinutes},
    );
  }

  /// Notifie le client que le travail a commencé
  Future<bool> notifyClientWorkStarted(String reservationId,
      {AppLocalizations? l10n}) async {
    return sendNotificationToClient(
      reservationId: reservationId,
      type: 'workStarted',
      title: l10n?.worker_businessWorkStarted ?? 'Déneigement commencé',
      message: l10n?.worker_businessWorkStartedBody ??
          'Le déneigement de votre véhicule a commencé',
    );
  }

  /// Notifie le client que le travail est terminé
  Future<bool> notifyClientWorkCompleted(
    String reservationId, {
    String? photoUrl,
    AppLocalizations? l10n,
  }) async {
    return sendNotificationToClient(
      reservationId: reservationId,
      type: 'workCompleted',
      title: l10n?.worker_businessWorkCompleted ?? 'Déneigement terminé!',
      message:
          l10n?.worker_businessWorkCompletedBody ?? 'Votre véhicule est prêt',
      metadata: photoUrl != null ? {'photoUrl': photoUrl} : null,
    );
  }

  /// Envoie un message au client
  Future<bool> sendMessageToClient(
    String reservationId,
    String message, {
    AppLocalizations? l10n,
  }) async {
    return sendNotificationToClient(
      reservationId: reservationId,
      type: 'workerMessage',
      title: l10n?.worker_businessWorkerMessage ?? 'Message du déneigeur',
      message: message,
    );
  }

  // ===== Méthodes privées =====

  void _addToCache(String jobId) {
    _notifiedJobIds.add(jobId);
    // Nettoyer le cache si trop grand
    if (_notifiedJobIds.length > _maxCacheSize) {
      _notifiedJobIds.remove(_notifiedJobIds.first);
    }
  }

  void _emitEvent(
    WorkerNotificationType type, {
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    _eventController.add(WorkerNotificationEvent(
      type: type,
      title: title,
      message: message,
      data: data ?? {},
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required bool isUrgent,
  }) async {
    // Utilise le service de notification local existant
    // On crée un job factice avec les paramètres minimum requis
    final dummyJob = WorkerJob(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      client: ClientInfo(
        id: 'system',
        firstName: title,
        lastName: '',
      ),
      vehicle: VehicleInfo(
        id: 'system',
        make: body,
        model: '',
      ),
      departureTime: DateTime.now(),
      serviceOptions: const [],
      totalPrice: 0,
      isPriority: isUrgent,
      status: JobStatus.pending,
      createdAt: DateTime.now(),
    );

    await _localNotificationService.notifyNewJob(dummyJob);
  }

  /// Nettoie le cache des jobs notifiés
  void clearNotificationCache() {
    _notifiedJobIds.clear();
  }

  /// Libère les ressources
  void dispose() {
    _eventController.close();
  }
}

/// Événement de notification pour les workers
class WorkerNotificationEvent {
  final WorkerNotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const WorkerNotificationEvent({
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  bool get isUrgent =>
      type == WorkerNotificationType.newJobAvailable &&
      (data['isPriority'] == true);

  @override
  String toString() => 'WorkerNotificationEvent($type: $title)';
}
