import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../shared/widgets/app_button.dart';

class NewReservationScreen extends StatefulWidget {
  const NewReservationScreen({super.key});

  @override
  State<NewReservationScreen> createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  // Clé API Google Places - À remplacer par votre clé
  static const String kGoogleApiKey = 'AIzaSyC4JjnG-g798JbVyR_wPOS-ORvjHntzfps';

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
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 'urgent',
      'name': 'Service Urgent',
      'description': 'Intervention rapide sous 2h',
      'price': 75.0,
      'icon': Icons.flash_on,
      'color': const Color(0xFFFFA000),
    },
    {
      'id': 'subscription',
      'name': 'Abonnement Saisonnier',
      'description': 'Service illimité pour l\'hiver',
      'price': 400.0,
      'icon': Icons.star,
      'color': const Color(0xFF10B981),
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
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white,
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
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
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
                title: const Text(
                  'Type de service',
                  style: TextStyle(color: Colors.white),
                ),
                content: _buildServiceTypeStep(),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text(
                  'Adresse',
                  style: TextStyle(color: Colors.white),
                ),
                content: _buildAddressStep(),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text(
                  'Date et heure',
                  style: TextStyle(color: Colors.white),
                ),
                content: _buildDateTimeStep(),
                isActive: _currentStep >= 2,
                state:
                    _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text(
                  'Confirmation',
                  style: TextStyle(color: Colors.white),
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
        const Text(
          'Choisissez le type de service',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? service['color'] : Colors.white.withOpacity(0.3),
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
                color: Colors.white,
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
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.grey[600] : Colors.white70,
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
                color: isSelected ? service['color'] : Colors.white,
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
        const Text(
          'Entrez votre adresse',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Commencez à taper pour voir les suggestions',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),

        // Champ d'adresse avec autocomplétion Google Places
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedAddress.isEmpty
                  ? Colors.grey.withOpacity(0.3)
                  : const Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _addressController,
            googleAPIKey: kGoogleApiKey,
            inputDecoration: InputDecoration(
              hintText: 'Ex: 123 Rue Principale, Montréal',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.location_on,
                color: _selectedAddress.isEmpty
                    ? Colors.grey
                    : const Color(0xFF3B82F6),
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
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prediction.description ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
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
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF10B981),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Adresse confirmée',
                    style: TextStyle(
                      color: Color(0xFF10B981),
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
                  child: const Text(
                    'Modifier',
                    style: TextStyle(color: Color(0xFF10B981)),
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
        const Text(
          'Choisissez la date et l\'heure',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDate != null
                      ? const Color(0xFF3B82F6)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _selectedDate != null
                        ? const Color(0xFF3B82F6)
                        : Colors.grey,
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
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 16),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTime != null
                      ? const Color(0xFF3B82F6)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: _selectedTime != null
                        ? const Color(0xFF3B82F6)
                        : Colors.grey,
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
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Notes supplémentaires
        const Text(
          'Notes supplémentaires (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Ex: Accès par l\'arrière, gros banc de neige...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de votre réservation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
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
            color: const Color(0xFF3B82F6),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _selectedDate != null
                ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!)
                : 'Non sélectionnée',
            color: const Color(0xFF10B981),
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            icon: Icons.access_time,
            label: 'Heure',
            value: _selectedTime != null
                ? _selectedTime!.format(context)
                : 'Non sélectionnée',
            color: const Color(0xFFFFA000),
          ),
          if (_notes.isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.note,
              label: 'Notes',
              value: _notes,
              color: const Color(0xFF8B5CF6),
            ),
          ],
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prix estimé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  '${_estimatedPrice.toStringAsFixed(2)}\$',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
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
            color: color.withOpacity(0.1),
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
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
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
        backgroundColor: Colors.red,
      ),
    );
  }

  void _confirmReservation() {
    // TODO: Envoyer la réservation au backend
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
            SizedBox(width: 12),
            Text('Réservation confirmée !'),
          ],
        ),
        content: const Text(
          'Votre réservation a été confirmée avec succès. '
          'Un déneigeur vous sera assigné sous peu.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Retour à l'accueil
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
