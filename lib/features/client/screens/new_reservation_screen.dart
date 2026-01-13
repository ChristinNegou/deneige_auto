import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

class NewReservationScreen extends StatefulWidget {
  const NewReservationScreen({super.key});

  @override
  State<NewReservationScreen> createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  // Clé API Google Places - Chargée depuis la configuration centralisée
  static String get kGoogleApiKey => AppConfig.googleMapsApiKey;

  int _currentStep = 0;
  String _selectedServiceType = 'standard';
  String _selectedAddress = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _notes = '';
  double _estimatedPrice = 0.0;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _serviceTypes = [
    {
      'id': 'standard',
      'name': 'Déneigement Standard',
      'description': 'Service de déneigement régulier',
      'price': 50.0,
      'icon': Icons.ac_unit,
      'color': AppTheme.info,
    },
    {
      'id': 'urgent',
      'name': 'Service Urgent',
      'description': 'Intervention rapide sous 2h',
      'price': 75.0,
      'icon': Icons.flash_on,
      'color': AppTheme.warning,
    },
    {
      'id': 'subscription',
      'name': 'Abonnement Saisonnier',
      'description': 'Service illimité pour l\'hiver',
      'price': 400.0,
      'icon': Icons.star,
      'color': AppTheme.success,
    },
  ];

  @override
  void initState() {
    super.initState();
    _estimatedPrice = _serviceTypes.first['price'];
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réservation'),
        backgroundColor: AppTheme.primary2,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primary2, AppTheme.info],
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.textPrimary,
            ),
          ),
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: _currentStep == 3 ? 'Confirmer' : 'Suivant',
                        onPressed: details.onStepContinue,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: BorderSide(color: AppTheme.textPrimary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Précédent'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(
                  'Type de service',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                content: _buildServiceTypeStep(),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text(
                  'Adresse',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                content: _buildAddressStep(),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text(
                  'Date et heure',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                content: _buildDateTimeStep(),
                isActive: _currentStep >= 2,
                state:
                    _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: Text(
                  'Confirmation',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                content: _buildConfirmationStep(),
                isActive: _currentStep >= 3,
                state: StepState.indexed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez le type de service',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._serviceTypes.map((service) => _buildServiceCard(service)),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isSelected = _selectedServiceType == service['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedServiceType = service['id'];
          _estimatedPrice = service['price'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.textPrimary
              : AppTheme.textPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? service['color']
                : AppTheme.textPrimary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: service['color'],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                service['icon'],
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
                    service['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.shadowColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? AppTheme.textSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${service['price']}\$',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? service['color'] : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entrez votre adresse',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Commencez à taper pour voir les suggestions',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Champ d'adresse avec autocomplétion Google Places
        Container(
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedAddress.isEmpty
                  ? AppTheme.textTertiary.withValues(alpha: 0.3)
                  : AppTheme.info,
              width: 2,
            ),
          ),
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _addressController,
            googleAPIKey: kGoogleApiKey,
            inputDecoration: InputDecoration(
              hintText: 'Ex: 123 Rue Principale, Montréal',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.location_on,
                color: _selectedAddress.isEmpty
                    ? AppTheme.textTertiary
                    : AppTheme.info,
              ),
            ),
            debounceTime: 800,
            countries: const ["ca"],
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction prediction) {
              setState(() {
                _selectedAddress = prediction.description ?? '';
              });
            },
            itemClick: (Prediction prediction) {
              _addressController.text = prediction.description ?? '';
              _addressController.selection = TextSelection.fromPosition(
                TextPosition(offset: prediction.description?.length ?? 0),
              );
              setState(() {
                _selectedAddress = prediction.description ?? '';
              });
            },
            seperatedBuilder: const Divider(),
            containerHorizontalPadding: 10,
            itemBuilder: (context, index, Prediction prediction) {
              return Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.info,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prediction.description ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            isCrossBtnShown: true,
          ),
        ),

        if (_selectedAddress.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.success,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adresse confirmée',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAddress = '';
                      _addressController.clear();
                    });
                  },
                  child: Text(
                    'Modifier',
                    style: TextStyle(color: AppTheme.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez la date et l\'heure',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Sélecteur de date
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDate != null
                      ? AppTheme.info
                      : AppTheme.textTertiary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _selectedDate != null
                        ? AppTheme.info
                        : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                              .format(_selectedDate!)
                          : 'Sélectionner une date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: AppTheme.textTertiary, size: 16),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Sélecteur d'heure
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectTime(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTime != null
                      ? AppTheme.info
                      : AppTheme.textTertiary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: _selectedTime != null
                        ? AppTheme.info
                        : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Sélectionner une heure',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedTime != null
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: AppTheme.textTertiary, size: 16),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Notes supplémentaires
        Text(
          'Notes supplémentaires (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ex: Accès par l\'arrière, gros banc de neige...',
            hintStyle: TextStyle(color: AppTheme.textTertiary),
            filled: true,
            fillColor: AppTheme.textPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppTheme.textTertiary.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppTheme.textTertiary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.info, width: 2),
            ),
          ),
          onChanged: (value) {
            _notes = value;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final service = _serviceTypes.firstWhere(
      (s) => s['id'] == _selectedServiceType,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de votre réservation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary2,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            icon: Icons.ac_unit,
            label: 'Service',
            value: service['name'],
            color: service['color'],
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.location_on,
            label: 'Adresse',
            value: _selectedAddress,
            color: AppTheme.info,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _selectedDate != null
                ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!)
                : 'Non sélectionnée',
            color: AppTheme.success,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.access_time,
            label: 'Heure',
            value: _selectedTime != null
                ? _selectedTime!.format(context)
                : 'Non sélectionnée',
            color: AppTheme.warning,
          ),
          if (_notes.isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.note,
              label: 'Notes',
              value: _notes,
              color: AppTheme.primary2,
            ),
          ],
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prix estimé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary2,
                  ),
                ),
                Text(
                  '${_estimatedPrice.toStringAsFixed(2)}\$',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Sélectionner une date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.info,
              onPrimary: AppTheme.textPrimary,
              onSurface: AppTheme.shadowColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.info,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.info,
              onPrimary: AppTheme.textPrimary,
              surface: AppTheme.textPrimary,
              onSurface: AppTheme.shadowColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedServiceType.isEmpty) {
      _showError('Veuillez sélectionner un type de service');
      return;
    }

    if (_currentStep == 1 && _selectedAddress.isEmpty) {
      _showError('Veuillez entrer une adresse');
      return;
    }

    if (_currentStep == 2) {
      if (_selectedDate == null) {
        _showError('Veuillez sélectionner une date');
        return;
      }
      if (_selectedTime == null) {
        _showError('Veuillez sélectionner une heure');
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _confirmReservation();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _confirmReservation() {
    // TODO: Envoyer la réservation au backend
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 32),
            const SizedBox(width: 12),
            const Text('Réservation confirmée !'),
          ],
        ),
        content: const Text(
          'Votre réservation a été confirmée avec succès. '
          'Un déneigeur vous sera assigné sous peu.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Fermer le dialog d'abord
              Navigator.pop(context);
              // Vérifier qu'on peut retourner en arrière avant de pop
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Retour à l'accueil
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.info,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
