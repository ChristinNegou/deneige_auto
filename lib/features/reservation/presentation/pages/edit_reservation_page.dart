import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/vehicle.dart';
import '../bloc/edit_reservation_bloc.dart';

class EditReservationPage extends StatelessWidget {
  final Reservation reservation;

  const EditReservationPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<EditReservationBloc>()..add(LoadEditReservationData(reservation)),
      child: const EditReservationView(),
    );
  }
}

class EditReservationView extends StatefulWidget {
  const EditReservationView({super.key});

  @override
  State<EditReservationView> createState() => _EditReservationViewState();
}

class _EditReservationViewState extends State<EditReservationView> {
  final TextEditingController _addressController = TextEditingController();
  bool _isSearchingAddress = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditReservationBloc, EditReservationState>(
      listener: (context, state) {
        if (state.isUpdateSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Réservation modifiée avec succès'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Retour avec succès
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Initialize address controller when data is loaded
        if (!state.isLoadingData &&
            state.locationAddress != null &&
            _addressController.text.isEmpty) {
          _addressController.text = state.locationAddress!;
        }
      },
      builder: (context, state) {
        if (state.isLoadingData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Modifier la réservation')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Vérifier si la réservation peut être éditée
        if (state.originalReservation != null &&
            !state.originalReservation!.canBeEdited) {
          return Scaffold(
            appBar: AppBar(title: const Text('Modifier la réservation')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block,
                      size: 64,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Modification impossible',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cette réservation ne peut plus être modifiée.\nSeules les réservations en attente peuvent être éditées.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Modifier la réservation'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!state.hasChanges)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modifiez les informations ci-dessous',
                          style: TextStyle(color: AppTheme.info),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!state.hasChanges) const SizedBox(height: 16),
              _buildVehicleSection(context, state),
              const SizedBox(height: 16),
              _buildParkingSpotSection(context, state),
              const SizedBox(height: 16),
              _buildLocationSection(context, state),
              const SizedBox(height: 16),
              _buildDepartureTimeSection(context, state),
              const SizedBox(height: 16),
              _buildServiceOptionsSection(context, state),
              const SizedBox(height: 16),
              _buildPriceCard(context, state),
              const SizedBox(height: 24),
              _buildSubmitButton(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleSection(
      BuildContext context, EditReservationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car),
                const SizedBox(width: 8),
                Text(
                  'Véhicule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _getValidVehicleValue(state),
              decoration: const InputDecoration(
                labelText: 'Sélectionner un véhicule',
                border: OutlineInputBorder(),
              ),
              items: _buildVehicleItems(state),
              onChanged: (value) {
                if (value != null) {
                  final vehicle = _getAllVehicles(state).firstWhere(
                    (v) => v.id == value,
                  );
                  context
                      .read<EditReservationBloc>()
                      .add(UpdateVehicle(vehicle));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingSpotSection(
      BuildContext context, EditReservationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_parking),
                const SizedBox(width: 8),
                Text(
                  'Place de parking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _getValidParkingSpotValue(state),
              decoration: const InputDecoration(
                labelText: 'Sélectionner une place',
                border: OutlineInputBorder(),
              ),
              items: _buildParkingSpotItems(state),
              onChanged: (value) {
                if (value != null) {
                  final spot = _getAllParkingSpots(state).firstWhere(
                    (s) => s.id == value,
                  );
                  context
                      .read<EditReservationBloc>()
                      .add(UpdateParkingSpot(spot));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(
      BuildContext context, EditReservationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(
                  'Adresse du véhicule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                hintText: 'Ex: 123 Rue Principale, Montréal, QC',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.home),
                suffixIcon: _isSearchingAddress
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchAddress(context),
                      ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchAddress(context),
            ),
            if (state.locationAddress != null &&
                state.locationLatitude != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Position GPS enregistrée',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.success,
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
  }

  Future<void> _searchAddress(BuildContext context) async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isSearchingAddress = true);

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        if (context.mounted) {
          context.read<EditReservationBloc>().add(
                UpdateLocationAddress(
                  address: address,
                  latitude: location.latitude,
                  longitude: location.longitude,
                ),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Adresse validée avec succès'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Adresse non trouvée. Veuillez réessayer.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la recherche de l\'adresse'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  Widget _buildDepartureTimeSection(
      BuildContext context, EditReservationState state) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'fr_CA');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(
                  'Heure de départ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDateTime(context, state),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sélectionner une date et heure',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  state.departureTime != null
                      ? dateFormat.format(state.departureTime!)
                      : 'Aucune date sélectionnée',
                ),
              ),
            ),
            if (state.deadlineTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Deadline: ${dateFormat.format(state.deadlineTime!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(
      BuildContext context, EditReservationState state) async {
    final now = DateTime.now();
    final initialDate =
        state.departureTime ?? now.add(const Duration(hours: 2));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (selectedDate != null && context.mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime != null && context.mounted) {
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        context
            .read<EditReservationBloc>()
            .add(UpdateDepartureTime(newDateTime));
      }
    }
  }

  Widget _buildServiceOptionsSection(
      BuildContext context, EditReservationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.miscellaneous_services),
                const SizedBox(width: 8),
                Text(
                  'Options de service',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildServiceOptionTile(
              context,
              state,
              ServiceOption.windowScraping,
              'Grattage des vitres',
              '+5\$',
            ),
            _buildServiceOptionTile(
              context,
              state,
              ServiceOption.doorDeicing,
              'Déglaçage des portes',
              '+3\$',
            ),
            _buildServiceOptionTile(
              context,
              state,
              ServiceOption.wheelClearance,
              'Dégagement des roues',
              '+4\$',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOptionTile(
    BuildContext context,
    EditReservationState state,
    ServiceOption option,
    String title,
    String price,
  ) {
    final isSelected = state.selectedOptions.contains(option);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) {
        context
            .read<EditReservationBloc>()
            .add(ToggleServiceOptionEdit(option));
      },
      title: Text(title),
      subtitle: Text(price),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPriceCard(BuildContext context, EditReservationState state) {
    return Card(
      color: AppTheme.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix total',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.calculatedPrice != null
                      ? '${state.calculatedPrice!.toStringAsFixed(2)} \$'
                      : '0.00 \$',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            if (state.originalReservation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Prix original',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.originalReservation!.totalPrice.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, EditReservationState state) {
    final canSubmit = state.canSubmit && state.hasChanges;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSubmit && !state.isLoading
            ? () {
                context
                    .read<EditReservationBloc>()
                    .add(SubmitReservationUpdate());
              }
            : null,
        icon: state.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                ),
              )
            : const Icon(Icons.check),
        label: Text(
          state.isLoading
              ? 'Modification en cours...'
              : !state.hasChanges
                  ? 'Aucune modification'
                  : 'Enregistrer les modifications',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: canSubmit ? AppTheme.primary : AppTheme.textTertiary,
          foregroundColor: AppTheme.background,
        ),
      ),
    );
  }

  // Helper methods pour gérer les dropdowns

  /// Obtient tous les véhicules (disponibles + sélectionné actuel)
  List<Vehicle> _getAllVehicles(EditReservationState state) {
    final allVehicles = <Vehicle>[];

    // Ajouter tous les véhicules disponibles
    allVehicles.addAll(state.availableVehicles);

    // Ajouter le véhicule sélectionné s'il n'est pas déjà dans la liste
    if (state.selectedVehicle != null) {
      final isAlreadyInList =
          allVehicles.any((v) => v.id == state.selectedVehicle!.id);
      if (!isAlreadyInList) {
        allVehicles.add(state.selectedVehicle!);
      }
    }

    return allVehicles;
  }

  /// Construit les items du dropdown véhicules
  List<DropdownMenuItem<String>> _buildVehicleItems(
      EditReservationState state) {
    return _getAllVehicles(state).map((vehicle) {
      return DropdownMenuItem(
        value: vehicle.id,
        child: Text('${vehicle.displayName} (${vehicle.color})'),
      );
    }).toList();
  }

  /// Obtient une valeur valide pour le dropdown véhicules
  String? _getValidVehicleValue(EditReservationState state) {
    if (state.selectedVehicle == null) return null;

    final allVehicles = _getAllVehicles(state);
    final exists = allVehicles.any((v) => v.id == state.selectedVehicle!.id);

    return exists ? state.selectedVehicle!.id : null;
  }

  /// Obtient toutes les places de parking (disponibles + sélectionnée actuelle)
  List<ParkingSpot> _getAllParkingSpots(EditReservationState state) {
    final allSpots = <ParkingSpot>[];

    // Ajouter toutes les places disponibles
    allSpots.addAll(state.availableParkingSpots);

    // Ajouter la place sélectionnée si elle n'est pas déjà dans la liste
    if (state.selectedParkingSpot != null) {
      final isAlreadyInList =
          allSpots.any((s) => s.id == state.selectedParkingSpot!.id);
      if (!isAlreadyInList) {
        allSpots.add(state.selectedParkingSpot!);
      }
    }

    return allSpots;
  }

  /// Construit les items du dropdown places de parking
  List<DropdownMenuItem<String>> _buildParkingSpotItems(
      EditReservationState state) {
    return _getAllParkingSpots(state).map((spot) {
      return DropdownMenuItem(
        value: spot.id,
        child: Text(spot.displayName),
      );
    }).toList();
  }

  /// Obtient une valeur valide pour le dropdown places de parking
  String? _getValidParkingSpotValue(EditReservationState state) {
    if (state.selectedParkingSpot == null) return null;

    final allSpots = _getAllParkingSpots(state);
    final exists = allSpots.any((s) => s.id == state.selectedParkingSpot!.id);

    return exists ? state.selectedParkingSpot!.id : null;
  }
}
