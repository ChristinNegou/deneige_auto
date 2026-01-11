import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dialog affiché lorsqu'un utilisateur est suspendu
class SuspensionDialog extends StatelessWidget {
  final String message;
  final String? reason;
  final String? suspendedUntilDisplay;
  final VoidCallback? onDismiss;

  const SuspensionDialog({
    super.key,
    required this.message,
    this.reason,
    this.suspendedUntilDisplay,
    this.onDismiss,
  });

  /// Affiche le dialog de suspension
  static Future<void> show(
    BuildContext context, {
    required String message,
    String? reason,
    String? suspendedUntilDisplay,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuspensionDialog(
        message: message,
        reason: reason,
        suspendedUntilDisplay: suspendedUntilDisplay,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.block,
          color: AppTheme.error,
          size: 48,
        ),
      ),
      title: const Text(
        'Compte Suspendu',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raison:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.error,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (suspendedUntilDisplay != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Jusqu\'au: $suspendedUntilDisplay',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Contactez le support au "deneigeauto@yahoo.com" si vous pensez qu\'il s\'agit d\'une erreur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text(
              'Compris',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
