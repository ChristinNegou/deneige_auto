import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/reservation_summary_card.dart';
import '../../widgets/price_summary_card.dart';

class Step5SummaryScreen extends StatelessWidget {
  const Step5SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Localisation
              if (state.hasValidLocation) ...[
                _buildSectionHeader(
                    l10n.step5_location, Icons.location_on_rounded),
                const SizedBox(height: 12),
                _buildLocationCard(context, state),
                const SizedBox(height: 24),
              ],

              // Récapitulatif
              _buildSectionHeader(
                  l10n.step5_yourReservation, Icons.receipt_rounded),
              const SizedBox(height: 12),
              const ReservationSummaryCard(),

              const SizedBox(height: 24),

              // Prix
              _buildSectionHeader(l10n.step5_total, Icons.payments_rounded),
              const SizedBox(height: 12),
              const PriceSummaryCard(showBreakdown: true),

              const SizedBox(height: 24),

              // Garanties
              _buildSectionHeader(
                  l10n.step5_ourGuarantees, Icons.verified_user_rounded),
              const SizedBox(height: 12),
              _buildGuarantees(),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Text(title, style: AppTheme.headlineSmall);
  }

  Widget _buildLocationCard(BuildContext context, NewReservationState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.locationAddress ??
                  AppLocalizations.of(context)!.step2_positionDetected,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantees() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return _buildGuaranteesContent(l10n);
      },
    );
  }

  Widget _buildGuaranteesContent(AppLocalizations l10n) {
    final guarantees = [
      {
        'icon': Icons.cancel_outlined,
        'title': l10n.step5_freeCancellation,
        'subtitle': l10n.step5_upTo2hBefore
      },
      {
        'icon': Icons.verified_outlined,
        'title': l10n.step5_qualityGuarantee,
        'subtitle': l10n.step5_satisfiedOrRefunded
      },
      {
        'icon': Icons.camera_alt_outlined,
        'title': l10n.step5_photosAfter,
        'subtitle': l10n.step5_proofOfService
      },
      {
        'icon': Icons.timer_outlined,
        'title': l10n.step5_punctuality,
        'subtitle': l10n.step5_discountIfLate
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: guarantees.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < guarantees.length - 1) ...[
                const SizedBox(height: 10),
                Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}
