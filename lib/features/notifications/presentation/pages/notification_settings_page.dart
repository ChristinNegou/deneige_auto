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
        title: Text(
          l10n.notifications_title,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primary2),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary2, AppTheme.primary2.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary2.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active,
              color: AppTheme.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.notifications_title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _prefsService!.isEnabled
                      ? l10n.notifSettings_enabled
                      : l10n.notifSettings_disabled,
                  style: TextStyle(
                    color: AppTheme.textPrimary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _prefsService!.isEnabled,
            onChanged: (value) async {
              await _prefsService!.setEnabled(value);
              setState(() {});
            },
            activeThumbColor: AppTheme.textPrimary,
            activeTrackColor: AppTheme.textPrimary.withValues(alpha: 0.4),
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
        borderRadius: BorderRadius.circular(16),
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
          Divider(height: 1, color: AppTheme.border),
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
          Divider(height: 1, color: AppTheme.border),
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
          Divider(height: 1, color: AppTheme.border),
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
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.nights_stay, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.notifSettings_quietMode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
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
                Divider(height: 1, color: AppTheme.border),
                ListTile(
                  leading: Icon(Icons.schedule, color: AppTheme.primary2),
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
                  Divider(height: 1, color: AppTheme.border),
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
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            l10n.notifSettings_notifTypes,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
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
        borderRadius: BorderRadius.circular(16),
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
                color: AppTheme.primary2,
              ),
              const SizedBox(width: 12),
              Text(
                NotificationPreferencesService.localizedCategoryName(
                    categoryName, l10n),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFullyEnabled
                      ? AppTheme.success
                      : (isPartiallyEnabled
                          ? AppTheme.warning
                          : AppTheme.textTertiary),
                ),
                child: Icon(
                  isFullyEnabled
                      ? Icons.check
                      : (isPartiallyEnabled ? Icons.remove : Icons.close),
                  color: AppTheme.textPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, color: AppTheme.textTertiary),
            ],
          ),
          children: [
            Divider(height: 1, color: AppTheme.border),
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
                activeThumbColor: AppTheme.primary2,
              ),
            ),
            Divider(height: 1, color: AppTheme.border),
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
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.notifSettings_critical,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Switch(
              value: isEnabled,
              onChanged: (value) async {
                await _prefsService!.setTypeEnabled(type, value);
                setState(() {});
              },
              activeThumbColor: AppTheme.primary2,
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
      leading: Icon(icon, color: AppTheme.primary2),
      title: Text(
        title,
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: _prefsService!.isEnabled ? onChanged : null,
        activeThumbColor: AppTheme.primary2,
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
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary2,
              foregroundColor: AppTheme.textPrimary,
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
