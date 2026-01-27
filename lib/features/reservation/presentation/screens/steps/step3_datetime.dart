import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';

class Step3DateTimeScreen extends StatefulWidget {
  const Step3DateTimeScreen({super.key});

  @override
  State<Step3DateTimeScreen> createState() => _Step3DateTimeScreenState();
}

class _Step3DateTimeScreenState extends State<Step3DateTimeScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    final state = context.read<NewReservationBloc>().state;
    if (state.departureDateTime != null) {
      selectedDate = state.departureDateTime;
      selectedTime = TimeOfDay.fromDateTime(state.departureDateTime!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Date
              _buildSectionHeader(
                  AppLocalizations.of(context)!.step3_departureDate,
                  Icons.calendar_today_rounded),
              const SizedBox(height: 12),
              _buildDateSelector(context),

              const SizedBox(height: 28),

              // Section Heure
              _buildSectionHeader(
                  AppLocalizations.of(context)!.step3_departureTime,
                  Icons.access_time_rounded),
              const SizedBox(height: 12),
              _buildTimeSelector(context),
              const SizedBox(height: 12),
              _buildQuickTimes(),

              const SizedBox(height: 24),

              // Messages d'info
              if (state.departureDateTime != null) _buildConfirmation(state),

              if (state.isUrgent) ...[
                const SizedBox(height: 12),
                _buildUrgentWarning(),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final hasDate = selectedDate != null;

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDate
              ? AppTheme.primary.withValues(alpha: 0.05)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? AppTheme.primary : AppTheme.border,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.calendar_month, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDate
                        ? DateFormat(
                                'EEEE d MMMM',
                                Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? 'en_CA'
                                    : 'fr_CA')
                            .format(selectedDate!)
                        : AppLocalizations.of(context)!.step3_selectDate,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasDate
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                    ),
                  ),
                  if (hasDate)
                    Text(
                      DateFormat('yyyy').format(selectedDate!),
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    final hasTime = selectedTime != null;

    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasTime
              ? AppTheme.primary.withValues(alpha: 0.05)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime ? AppTheme.primary : AppTheme.border,
            width: hasTime ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.schedule, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hasTime
                    ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : AppLocalizations.of(context)!.step3_selectTime,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: hasTime ? AppTheme.textPrimary : AppTheme.textTertiary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimes() {
    final times = ['06:00', '07:00', '08:00', '09:00', '17:00', '18:00'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((time) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final isSelected =
            selectedTime?.hour == hour && selectedTime?.minute == minute;

        return GestureDetector(
          onTap: () {
            setState(
                () => selectedTime = TimeOfDay(hour: hour, minute: minute));
            _updateDateTime();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isSelected ? AppTheme.background : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmation(NewReservationState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat(
                      'EEEE d MMMM – HH:mm',
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'en_CA'
                          : 'fr_CA')
                  .format(state.departureDateTime!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.step3_urgentReservation,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.step3_urgencyFee,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.warning.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: AppTheme.background,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
      _updateDateTime();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppTheme.primary,
                onPrimary: AppTheme.background,
                surface: AppTheme.surface,
                onSurface: AppTheme.textPrimary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => selectedTime = picked);
      _updateDateTime();
    }
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
