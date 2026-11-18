import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/address_autocomplete_field.dart';

/// Etape Adresse : la position GPS remplit l'adresse toute seule ; sinon on
/// cherche l'adresse et on la choisit dans les suggestions. Pas de bouton
/// "valider" : choisir une suggestion suffit.
class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen>
    with WidgetsBindingObserver {
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Derniere position connue : classe les suggestions par proximite.
  double? _biasLat;
  double? _biasLon;

  NewReservationBloc get _bloc => context.read<NewReservationBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _bloc.state;
      if (state.locationAddress != null) {
        _addressController.text = state.locationAddress!;
      }
      if (!state.hasValidLocation && !state.isGettingLocation) {
        _bloc.add(GetCurrentLocation());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Au retour des reglages (GPS active, permission accordee), on reessaie.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed || !mounted) return;
    final state = _bloc.state;
    if (state.locationIssue != null &&
        !state.hasValidLocation &&
        !state.isGettingLocation) {
      _bloc.add(GetCurrentLocation());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<NewReservationBloc, NewReservationState>(
      listenWhen: (prev, curr) =>
          prev.locationAddress != curr.locationAddress ||
          prev.locationLatitude != curr.locationLatitude,
      listener: (context, state) {
        if (state.hasValidLocation) {
          _biasLat = state.locationLatitude;
          _biasLon = state.locationLongitude;
        }
        // Adresse trouvee par le GPS : on l'affiche si l'utilisateur ne tape pas
        if (state.locationAddress != null &&
            !_focusNode.hasFocus &&
            _addressController.text != state.locationAddress) {
          _addressController.text = state.locationAddress!;
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.step2_subtitle,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              if (state.locationIssue != null && !state.hasValidLocation) ...[
                _buildGpsBanner(context, state.locationIssue!),
                const SizedBox(height: 16),
              ],
              AddressAutocompleteField(
                controller: _addressController,
                focusNode: _focusNode,
                confirmedAddress:
                    state.hasValidLocation ? state.locationAddress : null,
                busy: state.isGettingLocation && _focusNode.hasFocus,
                biasLatitude: _biasLat,
                biasLongitude: _biasLon,
                externalHint: state.locationError,
                onEdited: () => _bloc.add(ClearLocation()),
                onSelected: (s) => _bloc.add(SetLocationFromSuggestion(
                  address: s.fullAddress,
                  latitude: s.latitude,
                  longitude: s.longitude,
                )),
                onSubmitFreeText: (text) =>
                    _bloc.add(SetLocationFromAddress(text)),
              ),
              if (state.locationIssue == null || state.hasValidLocation) ...[
                const SizedBox(height: 8),
                _buildUseMyLocation(context, state),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Un seul message, et l'action qui regle le probleme.
  Widget _buildGpsBanner(BuildContext context, LocationIssue issue) {
    final l10n = AppLocalizations.of(context)!;
    final (String message, String action, VoidCallback onPressed) =
        switch (issue) {
      LocationIssue.serviceDisabled => (
          l10n.step2_gpsOff,
          l10n.step2_enableGps,
          () => Geolocator.openLocationSettings(),
        ),
      LocationIssue.permissionDenied => (
          l10n.step2_gpsDenied,
          l10n.step2_allow,
          () => _bloc.add(GetCurrentLocation()),
        ),
      LocationIssue.permissionDeniedForever => (
          l10n.step2_gpsDenied,
          l10n.step2_openSettings,
          () => Geolocator.openAppSettings(),
        ),
      LocationIssue.unavailable => (
          l10n.step2_gpsUnavailable,
          l10n.step2_retry,
          () => _bloc.add(GetCurrentLocation()),
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded,
              size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(action,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildUseMyLocation(BuildContext context, NewReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final locating = state.isGettingLocation;

    return TextButton.icon(
      onPressed: locating
          ? null
          : () {
              _focusNode.unfocus();
              _bloc.add(GetCurrentLocation());
            },
      icon: locating
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.textSecondary),
            )
          : Icon(Icons.my_location_rounded, size: 18, color: AppTheme.primary),
      label: Text(
        locating ? l10n.step2_locating : l10n.step2_useMyLocation,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: locating ? AppTheme.textSecondary : AppTheme.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
    );
  }
}
