import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _prefsService!.isEnabled
                      ? 'Les notifications sont activées'
                      : 'Les notifications sont désactivées',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
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
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.volume_up,
            title: 'Sons',
            subtitle: 'Jouer un son pour les nouvelles notifications',
            value: _prefsService!.isSoundEnabled,
            onChanged: (value) async {
              await _prefsService!.setSoundEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrer pour les nouvelles notifications',
            value: _prefsService!.isVibrationEnabled,
            onChanged: (value) async {
              await _prefsService!.setVibrationEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.circle_notifications,
            title: 'Badge',
            subtitle: 'Afficher le compteur sur l\'icône de l\'app',
            value: _prefsService!.isBadgeEnabled,
            onChanged: (value) async {
              await _prefsService!.setBadgeEnabled(value);
              setState(() {});
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.preview,
            title: 'Aperçu',
            subtitle: 'Afficher le contenu des notifications',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.nights_stay, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Mode silencieux',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.do_not_disturb_on,
                title: 'Mode silencieux',
                subtitle: 'Pas de notifications pendant les heures définies',
                value: _prefsService!.isQuietHoursEnabled,
                onChanged: (value) async {
                  await _prefsService!.setQuietHoursEnabled(value);
                  setState(() {});
                },
              ),
              if (_prefsService!.isQuietHoursEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule, color: Color(0xFF8B5CF6)),
                  title: const Text('Heures'),
                  subtitle: Text(
                    'De ${_prefsService!.quietHoursStart} à ${_prefsService!.quietHoursEnd}',
                    style: const TextStyle(color: Color(0xFF8B5CF6)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showQuietHoursDialog(),
                ),
                if (_prefsService!.isCurrentlyQuietHours) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mode silencieux actuellement actif',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 13),
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
            'Les notifications urgentes seront toujours envoyées',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Types de notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
    final isFullyEnabled = _prefsService!.isCategoryFullyEnabled(categoryName);
    final isPartiallyEnabled =
        _prefsService!.isCategoryPartiallyEnabled(categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
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
                      ? Colors.green
                      : (isPartiallyEnabled ? Colors.orange : Colors.grey),
                ),
                child: Icon(
                  isFullyEnabled
                      ? Icons.check
                      : (isPartiallyEnabled ? Icons.remove : Icons.close),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            const Divider(height: 1),
            // Category toggle
            ListTile(
              dense: true,
              title: Text(
                isFullyEnabled ? 'Tout désactiver' : 'Tout activer',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              trailing: Switch(
                value: isFullyEnabled,
                onChanged: (value) async {
                  await _prefsService!.setCategoryEnabled(categoryName, value);
                  setState(() {});
                },
                activeColor: const Color(0xFF8B5CF6),
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
    final isEnabled = _prefsService!.isTypeEnabled(type);

    return ListTile(
      dense: true,
      leading: Icon(
        _getNotificationTypeIcon(type),
        size: 20,
        color: isEnabled ? Colors.grey[700] : Colors.grey[400],
      ),
      title: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 14,
          color: isEnabled ? Colors.grey[800] : Colors.grey[500],
        ),
      ),
      subtitle: Text(
        type.settingsDescription,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      trailing: type.isCritical
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Critique',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
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
              activeColor: const Color(0xFF8B5CF6),
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
      leading: Icon(icon, color: const Color(0xFF8B5CF6)),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: _prefsService!.isEnabled ? onChanged : null,
        activeColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildResetButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showResetConfirmation(),
        icon: const Icon(Icons.restore, size: 20),
        label: const Text('Réinitialiser les paramètres'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[600],
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Heures du mode silencieux'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Début'),
              subtitle: Text(_prefsService!.quietHoursStart),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _parseTime(_prefsService!.quietHoursStart),
                );
                if (time != null) {
                  await _prefsService!.setQuietHoursStart(_formatTime(time));
                  setState(() {});
                  if (mounted) Navigator.pop(context);
                  _showQuietHoursDialog();
                }
              },
            ),
            ListTile(
              title: const Text('Fin'),
              subtitle: Text(_prefsService!.quietHoursEnd),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _parseTime(_prefsService!.quietHoursEnd),
                );
                if (time != null) {
                  await _prefsService!.setQuietHoursEnd(_formatTime(time));
                  setState(() {});
                  if (mounted) Navigator.pop(context);
                  _showQuietHoursDialog();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser?'),
        content: const Text(
          'Tous les paramètres de notification seront remis à leurs valeurs par défaut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _prefsService!.resetToDefaults();
              setState(() {});
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paramètres réinitialisés'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('Réinitialiser'),
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
      case 'Réservations':
        return Icons.calendar_today;
      case 'Paiements':
        return Icons.payment;
      case 'Alertes':
        return Icons.warning;
      case 'Communications':
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
