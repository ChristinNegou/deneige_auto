import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Rangee de contact client : Appeler, Clavarder (action principale), SMS.
/// Appeler et SMS restent visibles sans numero : le gestionnaire informe
/// le deneigeur que le numero n'est pas disponible.
class ClientContactRow extends StatelessWidget {
  final bool hasPhone;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onSms;

  const ClientContactRow({
    super.key,
    required this.hasPhone,
    required this.onCall,
    required this.onChat,
    required this.onSms,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            icon: Icons.phone_outlined,
            label: l10n.common_call,
            enabled: hasPhone,
            onTap: onCall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.reservation_chat,
            filled: true,
            onTap: onChat,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactButton(
            icon: Icons.sms_outlined,
            label: l10n.common_sms,
            enabled: hasPhone,
            onTap: onSms,
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled
        ? AppTheme.onPrimary
        : (enabled ? AppTheme.textPrimary : AppTheme.textTertiary);
    return Material(
      color: filled ? AppTheme.primary : AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
