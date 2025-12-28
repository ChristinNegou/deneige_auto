import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
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
      if (!state.hasValidLocation && !state.isGettingLocation && !_hasTriedAutoLocation) {
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
          if (_addressController.text.isEmpty || _addressController.text != state.locationAddress) {
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
              _buildSectionHeader('Position GPS', Icons.gps_fixed_rounded),
              const SizedBox(height: 12),
              _buildGpsStatus(context, state),

              const SizedBox(height: 28),

              // Section Adresse
              _buildSectionHeader('Adresse', Icons.location_on_rounded),
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
        Icon(icon, size: 20, color: AppTheme.primary),
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
            ? Colors.green.withValues(alpha: 0.05)
            : isLoading
                ? Colors.blue.withValues(alpha: 0.05)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation
              ? Colors.green.withValues(alpha: 0.3)
              : isLoading
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey[200]!,
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
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.white,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : Icon(
                    hasLocation ? Icons.check_circle_rounded : Icons.location_searching,
                    size: 24,
                    color: hasLocation ? Colors.green : Colors.grey[400],
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
                      ? 'Recherche en cours...'
                      : hasLocation
                          ? 'Position détectée'
                          : 'Position non disponible, activé votre gps ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasLocation ? Colors.green[700] : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Veuillez patienter'
                      : hasLocation
                          ? 'Vérifiez l\'adresse ci-dessous'
                          : 'Entrez l\'adresse manuellement',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Bouton actualiser
          if (!isLoading)
            TextButton.icon(
              onPressed: () => context.read<NewReservationBloc>().add(GetCurrentLocation()),
              icon: Icon(Icons.refresh, size: 18, color: AppTheme.primary),
              label: Text(
                hasLocation ? 'Actualiser' : 'Réessayer',
                style: TextStyle(fontSize: 13, color: AppTheme.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          decoration: InputDecoration(
            hintText: 'Ex: 123 Rue Principale, Montréal',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            suffixIcon: _addressController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                    onPressed: () {
                      _addressController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<NewReservationBloc>().add(SetLocationFromAddress(value));
            }
          },
        ),

        // Message d'erreur
        if (error != null) ...[
          const SizedBox(height: 10),
          _buildMessage(error, Colors.orange, Icons.info_outline),
        ],

        // Message de succès
        if (state.hasValidLocation && error == null) ...[
          const SizedBox(height: 10),
          _buildMessage('Adresse validée', Colors.green, Icons.check_circle_outline),
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
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Valider l\'adresse', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),

        // Tip
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'L\'adresse aide nos déneigeurs à localiser votre véhicule',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
              style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
