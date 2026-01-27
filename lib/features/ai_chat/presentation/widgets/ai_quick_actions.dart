import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/ai_conversation.dart';

/// Widget pour afficher les actions rapides suggérées
class AIQuickActions extends StatelessWidget {
  final List<AIQuickAction> actions;
  final ValueChanged<AIQuickAction> onActionSelected;
  final bool enabled;

  const AIQuickActions({
    super.key,
    required this.actions,
    required this.onActionSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.aiChat_suggestions,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(action.label),
                    onPressed: enabled ? () => onActionSelected(action) : null,
                    avatar: _getIconForAction(action.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _getIconForAction(String actionId) {
    final iconData = switch (actionId) {
      'create_reservation' => Icons.add_circle_outline,
      'view_reservations' => Icons.list_alt,
      'pricing_info' => Icons.attach_money,
      'cancel_policy' => Icons.cancel_outlined,
      'contact_support' => Icons.support_agent,
      _ => Icons.chat_bubble_outline,
    };

    return Icon(iconData, size: 18);
  }
}
