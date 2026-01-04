import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';

class ReservationSuccessScreen extends StatefulWidget {
  final String? reservationId;

  const ReservationSuccessScreen({
    super.key,
    this.reservationId,
  });

  @override
  State<ReservationSuccessScreen> createState() =>
      _ReservationSuccessScreenState();
}

class _ReservationSuccessScreenState extends State<ReservationSuccessScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Animation Lottie de succès
                    const AppIllustration(
                      type: IllustrationType.success,
                      width: 150,
                      height: 150,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Réservation confirmée !',
                      style: AppTheme.headlineLarge.copyWith(
                        color: AppTheme.success,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Votre demande de déneigement a été enregistrée avec succès.',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (widget.reservationId != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          boxShadow: AppTheme.shadowSM,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Numéro de réservation',
                              style: AppTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.reservationId!,
                              style: AppTheme.headlineSmall.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Informations supplémentaires
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Prochaines étapes',
                                style: AppTheme.labelLarge.copyWith(
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                              '1. Un déneigeur sera assigné sous peu'),
                          _buildInfoRow('2. Vous recevrez une notification'),
                          _buildInfoRow(
                              '3. Suivez l\'avancement en temps réel'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boutons d'action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.home,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Retour à l\'accueil'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.reservations,
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('Voir mes réservations'),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.success,
                AppTheme.primary,
                AppTheme.secondary,
                Colors.white,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
