import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/worker_job.dart';

class WorkerNotificationService {
  static final WorkerNotificationService _instance =
      WorkerNotificationService._internal();
  factory WorkerNotificationService() => _instance;
  WorkerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

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

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> notifyNewJob(WorkerJob job, {AppLocalizations? l10n}) async {
    await _vibrate(isUrgent: job.isPriority);
    await _showNotification(
      title: job.isPriority
          ? (l10n?.worker_notifUrgentJob ?? '🚨 JOB URGENT!')
          : (l10n?.worker_notifNewJobAvailable ?? '📍 Nouveau job disponible'),
      body: l10n != null
          ? l10n.worker_notifNewJobBody(
              job.displayAddress,
              job.totalPrice.toStringAsFixed(2),
              job.distanceKm?.toStringAsFixed(1) ?? '?',
            )
          : '${job.displayAddress}\n${job.totalPrice.toStringAsFixed(2)}\$ - ${job.distanceKm?.toStringAsFixed(1) ?? "?"} km',
      isUrgent: job.isPriority,
      l10n: l10n,
    );
  }

  Future<void> notifyMultipleNewJobs(int count,
      {bool hasUrgent = false, AppLocalizations? l10n}) async {
    await _vibrate(isUrgent: hasUrgent);
    await _showNotification(
      title: hasUrgent
          ? (l10n?.worker_notifUrgentJobsAvailable ??
              '🚨 Nouveaux jobs urgents!')
          : (l10n?.worker_notifNewJobsAvailable ??
              '📍 Nouveaux jobs disponibles'),
      body: l10n?.worker_notifNewJobsNearby(count) ??
          '$count nouveau${count > 1 ? 'x' : ''} job${count > 1 ? 's' : ''} près de vous!',
      isUrgent: hasUrgent,
      l10n: l10n,
    );
  }

  Future<void> notifyJobAccepted(WorkerJob job,
      {AppLocalizations? l10n}) async {
    await _vibrateSuccess();
    await _showNotification(
      title: l10n?.worker_notifJobAccepted ?? '✅ Job accepté!',
      body: l10n?.worker_notifGoTo(job.displayAddress) ??
          'Rendez-vous à ${job.displayAddress}',
      isUrgent: false,
      l10n: l10n,
    );
  }

  Future<void> notifyJobCompleted(double earnings,
      {AppLocalizations? l10n}) async {
    await _vibrateSuccess();
    await _showNotification(
      title: l10n?.worker_notifJobDone ?? '🎉 Travail terminé!',
      body: l10n?.worker_notifEarned(earnings.toStringAsFixed(2)) ??
          'Vous avez gagné ${earnings.toStringAsFixed(2)}\$',
      isUrgent: false,
      l10n: l10n,
    );
  }

  Future<void> _vibrate({required bool isUrgent}) async {
    try {
      final hasVibratorResult = await Vibration.hasVibrator();
      final hasVibrator = hasVibratorResult == true;
      if (!hasVibrator) return;

      if (isUrgent) {
        await Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 400],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      } else {
        await Vibration.vibrate(
          pattern: [0, 150, 100, 150],
          intensities: [0, 200, 0, 200],
        );
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> _vibrateSuccess() async {
    try {
      final hasVibratorResult = await Vibration.hasVibrator();
      final hasVibrator = hasVibratorResult == true;
      if (!hasVibrator) return;
      await Vibration.vibrate(duration: 100);
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    required bool isUrgent,
    AppLocalizations? l10n,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        isUrgent ? 'urgent_jobs' : 'new_jobs',
        isUrgent
            ? (l10n?.worker_notifChannelUrgent ?? 'Jobs Urgents')
            : (l10n?.worker_notifChannelNew ?? 'Nouveaux Jobs'),
        channelDescription: isUrgent
            ? (l10n?.worker_notifChannelUrgentDesc ??
                'Notifications pour les jobs urgents')
            : (l10n?.worker_notifChannelNewDesc ??
                'Notifications pour les nouveaux jobs'),
        importance: isUrgent ? Importance.max : Importance.high,
        priority: isUrgent ? Priority.max : Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: isUrgent ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }
}
