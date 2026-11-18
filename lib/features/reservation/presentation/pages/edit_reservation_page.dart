import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/parking_spot.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/vehicle.dart';
import '../widgets/address_autocomplete_field.dart';
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
  final FocusNode _addressFocus = FocusNode();
  bool _addressInitialized = false;

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<EditReservationBloc, EditReservationState>(
      listener: (context, state) {
        if (state.isUpdateSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reservation_modifiedSuccess),
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

        // Adresse actuelle affichee une seule fois, au chargement
        if (!_addressInitialized &&
            !state.isLoadingData &&
            state.locationAddress != null) {
          _addressInitialized = true;
          _addressController.text = state.locationAddress!;
        }
      },
      builder: (context, state) {
        if (state.isLoadingData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.reservation_editTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Vérifier si la réservation peut être éditée
        if (state.originalReservation != null &&
            !state.originalReservation!.canBeEdited) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.reservation_editTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_clock_outlined,
                        size: 30,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.reservation_editImpossible,
                      textAlign: TextAlign.center,
                      style: AppTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.reservation_editImpossibleMessage,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.common_back),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.reservation_editTitle),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (!state.hasChanges) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.info, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.reservation_editSubtitle,
                          style:
                              AppTheme.bodySmall.copyWith(color: AppTheme.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildVehicleSection(context, state),
              const SizedBox(height: 24),
              _buildParkingSpotSection(context, state),
              const SizedBox(height: 24),
              _buildLocationSection(context, state),
              const SizedBox(height: 24),
              _buildDepartureTimeSection(context, state),
              const SizedBox(height: 24),
              _buildServiceOptionsSection(context, state),
              const SizedBox(height: 24),
              _buildPriceCard(context, state),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: SafeArea(
              top: false,
              child: _buildSubmitButton(context, state),
            ),
          ),
        );
      },
    );
  }

  /// Section de formulaire : un titre puis son contenu.
  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.headlineSmall),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildVehicleSection(
      BuildContext context, EditReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      l10n.reservation_vehicle,
      DropdownButtonFormField<String>(
        initialValue: _getValidVehicleValue(state),
        decoration: InputDecoration(
          labelText: l10n.reservation_selectVehicle,
          prefixIcon: const Icon(Icons.directions_car_filled_outlined),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        items: _buildVehicleItems(state),
        onChanged: (value) {
          if (value != null) {
            final vehicle = _getAllVehicles(state).firstWhere(
              (v) => v.id == value,
            );
            context.read<EditReservationBloc>().add(UpdateVehicle(vehicle));
          }
        },
      ),
    );
  }

  Widget _buildParkingSpotSection(
      BuildContext context, EditReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      l10n.reservation_location,
      DropdownButtonFormField<String>(
        initialValue: _getValidParkingSpotValue(state),
        decoration: InputDecoration(
          labelText: l10n.reservation_selectSpot,
          prefixIcon: const Icon(Icons.local_parking_rounded),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        items: _buildParkingSpotItems(state),
        onChanged: (value) {
          if (value != null) {
            final spot = _getAllParkingSpots(state).firstWhere(
              (s) => s.id == value,
            );
            context.read<EditReservationBloc>().add(UpdateParkingSpot(spot));
          }
        },
      ),
    );
  }

  /// Adresse : on cherche et on choisit une suggestion. Tant que le texte
  /// ne correspond pas a une suggestion choisie, l'enregistrement est bloque.
  Widget _buildLocationSection(
      BuildContext context, EditReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<EditReservationBloc>();
    return _buildSection(
      l10n.reservation_vehicleAddress,
      AddressAutocompleteField(
        controller: _addressController,
        focusNode: _addressFocus,
        confirmedAddress: state.addressPending ? null : state.locationAddress,
        biasLatitude: state.locationLatitude,
        biasLongitude: state.locationLongitude,
        onEdited: () => bloc.add(AddressEdited()),
        onSelected: (s) => bloc.add(UpdateLocationAddress(
          address: s.fullAddress,
          latitude: s.latitude,
          longitude: s.longitude,
        )),
      ),
    );
  }

  Widget _buildDepartureTimeSection(
      BuildContext context, EditReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat(
        'EEEE d MMMM, HH:mm',
        Localizations.localeOf(context).languageCode == 'en'
            ? 'en_CA'
            : 'fr_CA');

    return _buildSection(
      l10n.reservation_departureTime,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _selectDateTime(context, state),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.reservation_selectDateTime,
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: const Icon(Icons.chevron_right_rounded),
              ),
              child: Text(
                state.departureTime != null
                    ? dateFormat.format(state.departureTime!)
                    : l10n.reservation_noDateSelected,
                style: AppTheme.bodyLarge,
              ),
            ),
          ),
          if (state.deadlineTime != null) ...[
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!
                  .reservation_deadline(dateFormat.format(state.deadlineTime!)),
              style: AppTheme.bodySmall,
            ),
          ],
        ],
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
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
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (
        ServiceOption.windowScraping,
        l10n.reservation_windowScraping,
        l10n.service_windowScraping5,
      ),
      (
        ServiceOption.doorDeicing,
        l10n.reservation_doorDeicing,
        l10n.service_doorDeicing3,
      ),
      (
        ServiceOption.wheelClearance,
        l10n.reservation_wheelClearing,
        l10n.service_wheelClearing4,
      ),
    ];

    return _buildSection(
      l10n.reservation_serviceOptions,
      GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const Divider(indent: 56),
              _buildServiceOptionTile(
                context,
                state,
                options[i].$1,
                options[i].$2,
                options[i].$3,
              ),
            ],
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
      title: Text(title, style: AppTheme.labelLarge),
      subtitle: Text(price, style: AppTheme.bodySmall),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  /// Nouveau prix, avec l'ancien barre pour comparer.
  /// Le prix paye ne change pas a la modification ; si un choix le
  /// changerait, on explique comment proceder au lieu d'enregistrer.
  Widget _buildPriceCard(BuildContext context, EditReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final paid = state.originalReservation?.totalPrice ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.edit_paidPrice,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${paid.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppTheme.onPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        if (state.changesPrice) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: AppTheme.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.edit_priceChangeNotAllowed,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, EditReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit =
        state.canSubmit && state.hasChanges && !state.changesPrice;

    return ElevatedButton(
      onPressed: canSubmit && !state.isLoading
          ? () {
              context
                  .read<EditReservationBloc>()
                  .add(SubmitReservationUpdate());
            }
          : null,
      child: state.isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.onPrimary,
              ),
            )
          : Text(
              !state.hasChanges
                  ? l10n.reservation_noChanges
                  : l10n.reservation_saveChanges,
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
