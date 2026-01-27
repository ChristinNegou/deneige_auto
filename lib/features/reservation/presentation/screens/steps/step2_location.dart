import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';

class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _hasTriedAutoLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<NewReservationBloc>().state;
      if (!state.hasValidLocation &&
          !state.isGettingLocation &&
          !_hasTriedAutoLocation) {
        _hasTriedAutoLocation = true;
        context.read<NewReservationBloc>().add(GetCurrentLocation());
      }
      if (state.locationAddress != null && _addressController.text.isEmpty) {
        _addressController.text = state.locationAddress!;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewReservationBloc, NewReservationState>(
      listener: (context, state) {
        if (state.hasValidLocation && state.locationAddress != null) {
          if (_addressController.text.isEmpty ||
              _addressController.text != state.locationAddress) {
            _addressController.text = state.locationAddress!;
          }
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section GPS
              _buildSectionHeader(
                  AppLocalizations.of(context)!.step2_gpsPosition,
                  Icons.gps_fixed_rounded),
              const SizedBox(height: 12),
              _buildGpsStatus(context, state),

              const SizedBox(height: 28),

              // Section Adresse
              _buildSectionHeader(AppLocalizations.of(context)!.step2_address,
                  Icons.location_on_rounded),
              const SizedBox(height: 12),
              _buildAddressInput(context, state),

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
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGpsStatus(BuildContext context, NewReservationState state) {
    final bool hasLocation = state.hasValidLocation;
    final bool isLoading = state.isGettingLocation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasLocation
            ? AppTheme.successLight
            : isLoading
                ? AppTheme.infoLight
                : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation
              ? AppTheme.success.withValues(alpha: 0.3)
              : isLoading
                  ? AppTheme.info.withValues(alpha: 0.3)
                  : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          // Icône statut
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasLocation
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : Icon(
                    hasLocation
                        ? Icons.check_circle_rounded
                        : Icons.location_searching,
                    size: 24,
                    color:
                        hasLocation ? AppTheme.success : AppTheme.textTertiary,
                  ),
          ),
          const SizedBox(width: 14),

          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? AppLocalizations.of(context)!.step2_searching
                      : hasLocation
                          ? AppLocalizations.of(context)!.step2_positionDetected
                          : AppLocalizations.of(context)!
                              .step2_positionUnavailable,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        hasLocation ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? AppLocalizations.of(context)!.step2_pleaseWait
                      : hasLocation
                          ? AppLocalizations.of(context)!.step2_checkAddress
                          : AppLocalizations.of(context)!.step2_enterManually,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Bouton actualiser
          if (!isLoading)
            TextButton.icon(
              onPressed: () =>
                  context.read<NewReservationBloc>().add(GetCurrentLocation()),
              icon: Icon(Icons.refresh, size: 18, color: AppTheme.textPrimary),
              label: Text(
                hasLocation
                    ? AppLocalizations.of(context)!.step2_refresh
                    : AppLocalizations.of(context)!.step2_retry,
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressInput(BuildContext context, NewReservationState state) {
    final bool isLoading = state.isGettingLocation;
    final String? error = state.locationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ d'adresse
        TextField(
          controller: _addressController,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.reservation_addressHint,
            hintStyle: TextStyle(color: AppTheme.textTertiary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
            suffixIcon: _addressController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: AppTheme.textTertiary, size: 20),
                    onPressed: () {
                      _addressController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.textSecondary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context
                  .read<NewReservationBloc>()
                  .add(SetLocationFromAddress(value));
            }
          },
        ),

        // Message d'erreur
        if (error != null) ...[
          const SizedBox(height: 10),
          _buildMessage(error, AppTheme.warning, Icons.info_outline),
        ],

        // Message de succès
        if (state.hasValidLocation && error == null) ...[
          const SizedBox(height: 10),
          _buildMessage(AppLocalizations.of(context)!.step2_addressValidated,
              AppTheme.success, Icons.check_circle_outline),
        ],

        const SizedBox(height: 14),

        // Bouton valider
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading || _addressController.text.trim().isEmpty
                ? null
                : () => context.read<NewReservationBloc>().add(
                      SetLocationFromAddress(_addressController.text),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: AppTheme.surfaceContainer,
              disabledForegroundColor: AppTheme.textTertiary,
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.background),
                  )
                : Text(AppLocalizations.of(context)!.step2_validateAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),

        // Tip
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.lightbulb_outline,
                size: 16, color: AppTheme.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.step2_addressTip,
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessage(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(fontSize: 13, color: color.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
