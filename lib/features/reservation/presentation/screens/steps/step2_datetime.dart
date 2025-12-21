
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';

class Step2DateTimeScreen extends StatefulWidget {
  const Step2DateTimeScreen({Key? key}) : super(key: key);

  @override
  State<Step2DateTimeScreen> createState() => _Step2DateTimeScreenState();
}

class _Step2DateTimeScreenState extends State<Step2DateTimeScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    // ✅ Initialiser depuis le state BLoC si disponible
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50.withOpacity(0.3),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec illustration
                _buildHeader(context),

                const SizedBox(height: 28),

              // Date Picker
              _buildDatePicker(context, state),

              const SizedBox(height: 24),

              // Time Picker
              _buildTimePicker(context, state),

              const SizedBox(height: 32),

              // ✅ Message de validation si les deux sont sélectionnés
              if (selectedDate != null && selectedTime != null && state.departureDateTime != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date et heure validées',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_CA')
                                  .format(state.departureDateTime!),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Deadline info
              if (state.deadlineTime != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deadline de service',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Votre voiture sera déneigée avant ${DateFormat('HH:mm').format(state.deadlineTime!)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Urgent warning
              if (state.isUrgent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Réservation urgente',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Des frais d\'urgence de 40% seront appliqués',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ✅ Message informatif si une seule est sélectionnée
              if ((selectedDate != null && selectedTime == null) ||
                  (selectedDate == null && selectedTime != null)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Veuillez sélectionner une date'
                              : 'Veuillez sélectionner une heure',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape 2 sur 4',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Date et heure de départ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quand devez-vous partir ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, NewReservationState state) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: selectedDate != null
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                )
              : null,
          color: selectedDate != null ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedDate != null
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: selectedDate != null ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selectedDate != null
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: selectedDate != null ? 10 : 5,
              offset: Offset(0, selectedDate != null ? 5 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? DateFormat('EEEE d MMMM yyyy', 'fr_CA')
                        .format(selectedDate!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, NewReservationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _selectTime(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: selectedTime != null
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Colors.white,
                      ],
                    )
                  : null,
              color: selectedTime != null ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedTime != null
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: selectedTime != null ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selectedTime != null
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: selectedTime != null ? 10 : 5,
                  offset: Offset(0, selectedTime != null ? 5 : 2),
                ),
              ],
            ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heure',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedTime != null
                        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Sélectionner une heure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedTime != null
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    ),

    // Suggestions rapides pour les heures
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Heures fréquentes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickTimeChip('06:00'),
              _buildQuickTimeChip('07:00'),
              _buildQuickTimeChip('08:00'),
              _buildQuickTimeChip('09:00'),
              _buildQuickTimeChip('17:00'),
              _buildQuickTimeChip('18:00'),
            ],
          ),
        ],
      ),
    ),
    ],
    );
  }

  Widget _buildQuickTimeChip(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return InkWell(
      onTap: () {
        setState(() {
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        });
        _updateDateTime(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
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
      locale: const Locale('fr', 'CA'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
      // ✅ Mettre à jour immédiatement après sélection
      _updateDateTime(context);
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
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedTime = picked;
      });
      // ✅ Mettre à jour immédiatement après sélection
      _updateDateTime(context);
    }
  }

  void _updateDateTime(BuildContext context) {
    // ✅ Ne mettre à jour que si les DEUX sont sélectionnés
    if (selectedDate != null && selectedTime != null) {
      final dateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // ✅ Notifier le BLoC
      context.read<NewReservationBloc>().add(SelectDateTime(dateTime));

      // ✅ Debug print pour vérifier
      print('✅ DateTime mis à jour: $dateTime');

      // Message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date et heure enregistrées ✓'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}