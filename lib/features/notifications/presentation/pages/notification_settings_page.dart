import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification.dart';
import '../../services/notification_preferences_service.dart';

/// Page de paramètres des notifications - Style apps modernes (Uber, DoorDash)
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  NotificationPreferencesService? _prefsService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefsService = NotificationPreferencesService(prefs);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.notifications_title),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master toggle
                  _buildMasterToggle(),
                  const SizedBox(height: 24),

                  // Quick settings
                  _buildQuickSettings(),
                  const SizedBox(height: 24),

                  // Quiet Hours
                  _buildQuietHoursSection(),
                  const SizedBox(height: 24),

                  // Categories
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // Reset button
                  _buildResetButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterToggle() {
    final l10n = AppLocalizations.of(context)!;
    final enabled = _prefsService!.isEnabled;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: AppTheme.onPrimary,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notifications_title,
                  style: const TextStyle(
                    color: AppTheme.onPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? l10n.notifSettings_enabled
                      : l10n.notifSettings_disabled,
                  style: TextStyle(
                    color: AppTheme.onPrimary.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) async {
              await _prefsService!.setEnabled(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.volume_up,
            title: l10n.notifSettings_sounds,
            subtitle: l10n.notifSettings_soundsDesc,
            value: _prefsService!.isSoundEnabled,
            onChanged: (value) async {
              await _prefsService!.setSoundEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.vibration,
            title: l10n.notifSettings_vibration,
            subtitle: l10n.notifSettings_vibrationDesc,
            value: _prefsService!.isVibrationEnabled,
            onChanged: (value) async {
              await _prefsService!.setVibrationEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.circle_notifications,
            title: l10n.notifSettings_badge,
            subtitle: l10n.notifSettings_badgeDesc,
            value: _prefsService!.isBadgeEnabled,
            onChanged: (value) async {
              await _prefsService!.setBadgeEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.preview,
            title: l10n.notifSettings_preview,
            subtitle: l10n.notifSettings_previewDesc,
            value: _prefsService!.isPreviewEnabled,
            onChanged: (value) async {
              await _prefsService!.setPreviewEnabled(value);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l10n.notifSettings_quietMode,
            style: AppTheme.headlineSmall,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
            boxShadow: AppTheme.shadowSM,
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.do_not_disturb_on,
                title: l10n.notifSettings_quietMode,
                subtitle: l10n.notifSettings_quietModeDesc,
                value: _prefsService!.isQuietHoursEnabled,
                onChanged: (value) async {
                  await _prefsService!.setQuietHoursEnabled(value);
                  setState(() {});
                },
              ),
              if (_prefsService!.isQuietHoursEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded,
                      color: AppTheme.textSecondary),
                  title: Text(
                    l10n.notifSettings_hours,
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.notifSettings_hoursRange(
                        _prefsService!.quietHoursStart,
                        _prefsService!.quietHoursEnd),
                    style: TextStyle(color: AppTheme.primary2),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  onTap: () => _showQuietHoursDialog(),
                ),
                if (_prefsService!.isCurrentlyQuietHours) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: AppTheme.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.notifSettings_quietModeActive,
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.notifSettings_urgentAlways,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l10n.notifSettings_notifTypes,
            style: AppTheme.headlineSmall,
          ),
        ),
        ...NotificationPreferencesService.categories.entries.map((entry) {
          return _buildCategoryCard(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildCategoryCard(String categoryName, List<NotificationType> types) {
    final l10n = AppLocalizations.of(context)!;
    final isFullyEnabled = _prefsService!.isCategoryFullyEnabled(categoryName);
    final isPartiallyEnabled =
        _prefsService!.isCategoryPartiallyEnabled(categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                NotificationPreferencesService.localizedCategoryName(
                    categoryName, l10n),
                style: AppTheme.labelLarge,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFullyEnabled
                    ? Icons.check_circle_rounded
                    : (isPartiallyEnabled
                        ? Icons.remove_circle_rounded
                        : Icons.cancel_outlined),
                color: isFullyEnabled
                    ? AppTheme.success
                    : (isPartiallyEnabled
                        ? AppTheme.warning
                        : AppTheme.textTertiary),
                size: 20,
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, color: AppTheme.textTertiary),
            ],
          ),
          children: [
            const Divider(height: 1),
            // Category toggle
            ListTile(
              dense: true,
              title: Text(
                isFullyEnabled
                    ? l10n.notifSettings_disableAll
                    : l10n.notifSettings_enableAll,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              trailing: Switch(
                value: isFullyEnabled,
                onChanged: (value) async {
                  await _prefsService!.setCategoryEnabled(categoryName, value);
                  setState(() {});
                },
              ),
            ),
            const Divider(height: 1),
            // Individual types
            ...types.map((type) => _buildNotificationTypeTile(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeTile(NotificationType type) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = _prefsService!.isTypeEnabled(type);

    return ListTile(
      dense: true,
      leading: Icon(
        _getNotificationTypeIcon(type),
        size: 20,
        color: isEnabled ? AppTheme.textSecondary : AppTheme.textTertiary,
      ),
      title: Text(
        type.localizedDisplayName(l10n),
        style: TextStyle(
          fontSize: 14,
          color: isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
      subtitle: Text(
        type.localizedSettingsDescription(l10n),
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textTertiary,
        ),
      ),
      trailing: type.isCritical
          ? StatusBadge(
              label: l10n.notifSettings_critical,
              color: AppTheme.error,
              small: true,
            )
          : Switch(
              value: isEnabled,
              onChanged: (value) async {
                await _prefsService!.setTypeEnabled(type, value);
                setState(() {});
              },
            ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: AppTheme.labelLarge),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: _prefsService!.isEnabled ? onChanged : null,
      ),
    );
  }

  Widget _buildResetButton() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: TextButton.icon(
        onPressed: () => _showResetConfirmation(),
        icon: Icon(Icons.restore, size: 20, color: AppTheme.textSecondary),
        label: Text(
          l10n.notifSettings_resetSettings,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.notifSettings_quietHoursTitle,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n.notifSettings_start,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                _prefsService!.quietHoursStart,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              trailing: Icon(Icons.access_time, color: AppTheme.primary2),
              onTap: () async {
                final navigator = Navigator.of(dialogContext);
                final time = await showTimePicker(
                  context: dialogContext,
                  initialTime: _parseTime(_prefsService!.quietHoursStart),
                );
                if (time != null) {
                  await _prefsService!.setQuietHoursStart(_formatTime(time));
                  if (!mounted) return;
                  setState(() {});
                  navigator.pop();
                  _showQuietHoursDialog();
                }
              },
            ),
            ListTile(
              title: Text(
                l10n.notifSettings_end,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                _prefsService!.quietHoursEnd,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              trailing: Icon(Icons.access_time, color: AppTheme.primary2),
              onTap: () async {
                final navigator = Navigator.of(dialogContext);
                final time = await showTimePicker(
                  context: dialogContext,
                  initialTime: _parseTime(_prefsService!.quietHoursEnd),
                );
                if (time != null) {
                  await _prefsService!.setQuietHoursEnd(_formatTime(time));
                  if (!mounted) return;
                  setState(() {});
                  navigator.pop();
                  _showQuietHoursDialog();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.common_close,
              style: TextStyle(color: AppTheme.primary2),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          l10n.notifSettings_resetConfirm,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          l10n.notifSettings_resetConfirmMessage,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.common_cancel,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              await _prefsService!.resetToDefaults();
              if (!mounted) return;
              setState(() {});
              navigator.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.notifSettings_resetDone,
                    style: TextStyle(color: AppTheme.onPrimary),
                  ),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary2,
              foregroundColor: AppTheme.onPrimary,
            ),
            child: Text(l10n.notifSettings_reset),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'reservations':
        return Icons.calendar_today;
      case 'payments':
        return Icons.payment;
      case 'alerts':
        return Icons.warning;
      case 'communications':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reservationAssigned:
        return Icons.person_add;
      case NotificationType.workerEnRoute:
        return Icons.directions_car;
      case NotificationType.workStarted:
        return Icons.construction;
      case NotificationType.workCompleted:
        return Icons.check_circle;
      case NotificationType.reservationCancelled:
        return Icons.cancel;
      case NotificationType.paymentSuccess:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.refundProcessed:
        return Icons.money_off;
      case NotificationType.weatherAlert:
        return Icons.wb_cloudy;
      case NotificationType.urgentRequest:
        return Icons.priority_high;
      case NotificationType.searchingWorker:
        return Icons.person_search;
      case NotificationType.workerMessage:
        return Icons.message;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.tipReceived:
        return Icons.attach_money;
      case NotificationType.rating:
        return Icons.star;
      case NotificationType.systemNotification:
        return Icons.info;
    }
  }
}
