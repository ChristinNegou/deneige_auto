import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../domain/entities/worker_job.dart';

class WorkerNotificationService {
  static final WorkerNotificationService _instance = WorkerNotificationService._internal();
  factory WorkerNotificationService() => _instance;
  WorkerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  Future<void> notifyNewJob(WorkerJob job) async {
    await _vibrate(isUrgent: job.isPriority);
    await _showNotification(
      title: job.isPriority ? '🚨 JOB URGENT!' : '📍 Nouveau job disponible',
      body: '${job.displayAddress}\n${job.totalPrice.toStringAsFixed(2)}\$ - ${job.distanceKm?.toStringAsFixed(1) ?? "?"} km',
      isUrgent: job.isPriority,
    );
  }

  Future<void> notifyMultipleNewJobs(int count, {bool hasUrgent = false}) async {
    await _vibrate(isUrgent: hasUrgent);
    await _showNotification(
      title: hasUrgent ? '🚨 Nouveaux jobs urgents!' : '📍 Nouveaux jobs disponibles',
      body: '$count nouveau${count > 1 ? 'x' : ''} job${count > 1 ? 's' : ''} près de vous!',
      isUrgent: hasUrgent,
    );
  }

  Future<void> notifyJobAccepted(WorkerJob job) async {
    await _vibrateSuccess();
    await _showNotification(
      title: '✅ Job accepté!',
      body: 'Rendez-vous à ${job.displayAddress}',
      isUrgent: false,
    );
  }

  Future<void> notifyJobCompleted(double earnings) async {
    await _vibrateSuccess();
    await _showNotification(
      title: '🎉 Travail terminé!',
      body: 'Vous avez gagné ${earnings.toStringAsFixed(2)}\$',
      isUrgent: false,
    );
  }

  Future<void> _vibrate({required bool isUrgent}) async {
    try {
      final hasVibratorResult = await Vibration.hasVibrator();
      final hasVibrator = hasVibratorResult == true;
      if (!hasVibrator) return;

      if (isUrgent) {
        // Vibration urgente : 3 pulsations rapides
        await Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 400],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      } else {
        // Vibration normale : 2 pulsations
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
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        isUrgent ? 'urgent_jobs' : 'new_jobs',
        isUrgent ? 'Jobs Urgents' : 'Nouveaux Jobs',
        channelDescription: isUrgent
            ? 'Notifications pour les jobs urgents'
            : 'Notifications pour les nouveaux jobs',
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

