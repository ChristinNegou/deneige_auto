import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';

/// Etape Date et heure : le jour en un geste (aujourd'hui, demain ou autre),
/// l'heure de depart, puis une ligne neutre qui dit quand le vehicule sera pret
/// ou pourquoi l'heure choisie ne convient pas.
class Step3DateTimeScreen extends StatefulWidget {
  const Step3DateTimeScreen({super.key});

  @override
  State<Step3DateTimeScreen> createState() => _Step3DateTimeScreenState();
}

class _Step3DateTimeScreenState extends State<Step3DateTimeScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  static const _quickTimes = [
    TimeOfDay(hour: 6, minute: 0),
    TimeOfDay(hour: 7, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<NewReservationBloc>().state;
    if (state.departureDateTime != null) {
      selectedDate = state.departureDateTime;
      selectedTime = TimeOfDay.fromDateTime(state.departureDateTime!);
    }
  }

  String get _localeTag =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en_CA' : 'fr_CA';

  String _formatTime(TimeOfDay t) =>
      DateFormat.Hm(_localeTag).format(DateTime(2000, 1, 1, t.hour, t.minute));

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  /// Heure trop proche pour laisser le temps au deneigeur (regle du serveur).
  bool _isTooSoon(DateTime date, TimeOfDay time) {
    final departure =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final earliest = DateTime.now()
        .add(const Duration(minutes: AppConfig.minReservationTimeMinutes));
    return departure.isBefore(earliest);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        final tooSoon = selectedDate != null &&
            selectedTime != null &&
            _isTooSoon(selectedDate!, selectedTime!);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.step3_departureDate, style: AppTheme.headlineSmall),
              const SizedBox(height: 12),
              _buildDateChoices(context),
              const SizedBox(height: 28),
              Text(l10n.step3_departureTime, style: AppTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.step3_timeHelp,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildTimeSelector(context),
              const SizedBox(height: 12),
              _buildQuickTimes(),
              const SizedBox(height: 20),
              if (tooSoon)
                _buildNote(
                  icon: Icons.info_outline_rounded,
                  text: l10n.step3_tooSoon(AppConfig.minReservationTimeMinutes),
                  color: AppTheme.error,
                )
              else if (state.deadlineTime != null &&
                  state.departureDateTime != null) ...[
                _buildNote(
                  icon: Icons.schedule_rounded,
                  text: l10n.step3_readyBy(
                      _formatTime(TimeOfDay.fromDateTime(state.deadlineTime!))),
                  color: AppTheme.textPrimary,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Aujourd'hui, demain, ou une autre date via le calendrier.
  Widget _buildDateChoices(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tomorrow = _today.add(const Duration(days: 1));
    final isToday = _sameDay(selectedDate, _today);
    final isTomorrow = _sameDay(selectedDate, tomorrow);
    final isOther = selectedDate != null && !isToday && !isTomorrow;

    return Row(
      children: [
        Expanded(
          child: _dateChip(
            label: l10n.step3_today,
            selected: isToday,
            onTap: () => _setDate(_today),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _dateChip(
            label: l10n.step3_tomorrow,
            selected: isTomorrow,
            onTap: () => _setDate(tomorrow),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _dateChip(
            label: isOther
                ? DateFormat('EEE d MMM', _localeTag).format(selectedDate!)
                : l10n.step3_otherDate,
            icon: Icons.calendar_month_rounded,
            selected: isOther,
            onTap: () => _pickDate(context),
          ),
        ),
      ],
    );
  }

  Widget _dateChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppTheme.primary : AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 16,
                      color: selected
                          ? AppTheme.onPrimary
                          : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? AppTheme.onPrimary : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTime = selectedTime != null;

    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasTime ? AppTheme.primary : AppTheme.border,
          width: hasTime ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _pickTime(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded,
                  color: AppTheme.textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasTime ? _formatTime(selectedTime!) : l10n.step3_selectTime,
                  style: TextStyle(
                    fontSize: hasTime ? 18 : 15,
                    fontWeight: hasTime ? FontWeight.w800 : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color:
                        hasTime ? AppTheme.textPrimary : AppTheme.textTertiary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  /// Heures frequentes ; celles deja trop proches aujourd'hui sont grisees.
  Widget _buildQuickTimes() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickTimes.map((time) {
        final isSelected = selectedTime == time;
        final disabled =
            selectedDate != null && _isTooSoon(selectedDate!, time);

        return Semantics(
          button: true,
          selected: isSelected,
          enabled: !disabled,
          child: GestureDetector(
            onTap: disabled ? null : () => _setTime(time),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isSelected
                      ? AppTheme.onPrimary
                      : disabled
                          ? AppTheme.textTertiary.withValues(alpha: 0.6)
                          : AppTheme.textPrimary,
                  decoration: disabled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Ligne d'information sobre : icone + texte, sans fond colore.
  Widget _buildNote({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _setDate(DateTime date) {
    setState(() => selectedDate = date);
    _updateDateTime();
  }

  void _setTime(TimeOfDay time) {
    setState(() => selectedTime = time);
    _updateDateTime();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? _today.add(const Duration(days: 2)),
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 30)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null && mounted) _setDate(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) _setTime(picked);
  }

  void _updateDateTime() {
    if (selectedDate != null && selectedTime != null) {
      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      context.read<NewReservationBloc>().add(SelectDateTime(dateTime));
    }
  }
}
