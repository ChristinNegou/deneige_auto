import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    // Essayer automatiquement de capturer la position GPS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<NewReservationBloc>().state;
      if (!state.hasValidLocation && !state.isGettingLocation && !_hasTriedAutoLocation) {
        _hasTriedAutoLocation = true;
        context.read<NewReservationBloc>().add(GetCurrentLocation());
      }
      // Pré-remplir le champ si une adresse existe déjà
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
        // Mettre à jour le champ d'adresse quand la localisation est obtenue
        if (state.hasValidLocation && state.locationAddress != null) {
          if (_addressController.text.isEmpty || _addressController.text != state.locationAddress) {
            _addressController.text = state.locationAddress!;
          }
        }
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50.withValues(alpha: 0.3),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 28),

                // Carte de localisation
                _buildLocationCard(context, state),

                const SizedBox(height: 24),

                // Champ d'adresse
                _buildAddressInput(context, state),

                const SizedBox(height: 24),

                // Info card
                _buildInfoCard(),

                const SizedBox(height: 100),
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
            Colors.blue.shade100.withValues(alpha: 0.5),
            Colors.blue.shade50.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 40,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Étape 2 sur 5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Où se trouve votre véhicule?',
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

  Widget _buildLocationCard(BuildContext context, NewReservationState state) {
    final bool hasLocation = state.hasValidLocation;
    final bool isLoading = state.isGettingLocation;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône de statut
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: hasLocation
                  ? Colors.green.shade50
                  : isLoading
                      ? Colors.blue.shade50
                      : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  )
                : Icon(
                    hasLocation ? Icons.check_circle : Icons.location_searching,
                    size: 50,
                    color: hasLocation ? Colors.green.shade600 : Colors.grey.shade400,
                  ),
          ),
          const SizedBox(height: 16),

          // Texte de statut
          Text(
            isLoading
                ? 'Recherche de votre position...'
                : hasLocation
                    ? 'Position détectée!'
                    : 'Position non détectée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasLocation ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            isLoading
                ? 'Veuillez patienter...'
                : hasLocation
                    ? 'Vérifiez ou modifiez l\'adresse ci-dessous'
                    : 'Entrez votre adresse manuellement',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Bouton pour réessayer la localisation
          OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    context.read<NewReservationBloc>().add(GetCurrentLocation());
                  },
            icon: Icon(
              Icons.my_location,
              color: isLoading ? Colors.grey : Colors.blue.shade600,
            ),
            label: Text(
              hasLocation ? 'Actualiser ma position' : 'Utiliser ma position GPS',
              style: TextStyle(
                color: isLoading ? Colors.grey : Colors.blue.shade600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Colors.blue.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInput(BuildContext context, NewReservationState state) {
    final bool isLoading = state.isGettingLocation;
    final String? error = state.locationError;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_location, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                'Adresse du véhicule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez l\'adresse complète où se trouve votre véhicule',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Champ de texte
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Ex: 123 Rue Principale, Montréal, QC',
              prefixIcon: Icon(Icons.home, color: Colors.grey[400]),
              suffixIcon: _addressController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _addressController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {}); // Pour mettre à jour le bouton
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<NewReservationBloc>().add(SetLocationFromAddress(value));
              }
            },
          ),

          // Message d'erreur
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Bouton de validation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading || _addressController.text.trim().isEmpty
                  ? null
                  : () {
                      context.read<NewReservationBloc>().add(
                            SetLocationFromAddress(_addressController.text),
                          );
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(isLoading ? 'Recherche...' : 'Valider cette adresse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),

          // Indicateur de succès
          if (state.hasValidLocation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adresse validée! Vous pouvez continuer.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pourquoi avons-nous besoin de cette information?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'L\'adresse permet à nos déneigeurs de localiser votre véhicule rapidement et d\'estimer le temps de trajet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
