import 'package:flutter/material.dart';

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
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.block,
          color: Colors.red.shade700,
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
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raison:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: TextStyle(
                      color: Colors.red.shade900,
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
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Jusqu\'au: $suspendedUntilDisplay',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Contactez le support si vous pensez qu\'il s\'agit d\'une erreur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
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
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
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
