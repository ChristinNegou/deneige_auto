import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.reservationSuccess_title,
                      style: AppTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      l10n.reservationSuccess_subtitle,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (widget.reservationId != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          '${l10n.reservationSuccess_reservationNumber} #${_shortReference(widget.reservationId!)}',
                          style: AppTheme.labelLarge.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Prochaines etapes : une vraie sequence, donc numerotee
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reservationSuccess_nextSteps,
                            style: AppTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(1, l10n.reservationSuccess_step1),
                          _buildInfoRow(2, l10n.reservationSuccess_step2),
                          _buildInfoRow(3, l10n.reservationSuccess_step3,
                              isLast: true),
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
                        child: Text(l10n.reservationSuccess_backToHome),
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
                        child: Text(l10n.reservationSuccess_viewReservations),
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
                AppTheme.accent,
                AppTheme.primary,
                AppTheme.primary2,
                AppTheme.primary3,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Reference courte et lisible a partir de l'identifiant technique.
  String _shortReference(String id) {
    final clean = id.replaceAll('-', '');
    return (clean.length > 6 ? clean.substring(clean.length - 6) : clean)
        .toUpperCase();
  }

  Widget _buildInfoRow(int number, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
