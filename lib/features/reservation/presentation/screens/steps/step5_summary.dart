import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/price_summary_card.dart';
import '../../widgets/service_option_info.dart';

/// Recapitulatif : une carte avec chaque choix et un lien pour le modifier,
/// le total (detail sur demande), puis les deux engagements reels du service.
class Step5SummaryScreen extends StatefulWidget {
  const Step5SummaryScreen({super.key});

  @override
  State<Step5SummaryScreen> createState() => _Step5SummaryScreenState();
}

// Index des etapes du parcours (voir NewReservationScreen)
const _stepVehicle = 0;
const _stepAddress = 1;
const _stepDateTime = 2;
const _stepOptions = 3;

class _Step5SummaryScreenState extends State<Step5SummaryScreen> {
  bool _showPriceDetail = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.step5_yourReservation, style: AppTheme.headlineSmall),
              const SizedBox(height: 12),
              _buildDetails(context, state),
              const SizedBox(height: 24),
              PriceSummaryCard(showBreakdown: _showPriceDetail),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showPriceDetail = !_showPriceDetail),
                icon: Icon(
                  _showPriceDetail
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppTheme.primary,
                ),
                label: Text(
                  _showPriceDetail
                      ? l10n.step5_hidePriceDetail
                      : l10n.step5_showPriceDetail,
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              _buildFact(Icons.event_busy_rounded, l10n.step5_cancelPolicy),
              const SizedBox(height: 10),
              _buildFact(Icons.photo_camera_outlined, l10n.step5_photoProof),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetails(BuildContext context, NewReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';

    final departure = state.departureDateTime;
    final readyBy = state.deadlineTime;
    final vehicle = state.selectedVehicle;

    final rows = <Widget>[
      _SummaryRow(
        label: l10n.step1_vehicle,
        value: vehicle?.displayName ?? '—',
        detail: vehicle?.licensePlate,
        step: _stepVehicle,
      ),
      _SummaryRow(
        label: l10n.summary_spot,
        value: _parkingLabel(l10n, state),
        step: _stepVehicle,
      ),
      _SummaryRow(
        label: l10n.step5_address,
        value: state.locationAddress ?? '—',
        step: _stepAddress,
      ),
      _SummaryRow(
        label: l10n.summary_departure,
        value: departure == null
            ? '—'
            : '${DateFormat('EEE d MMM', locale).format(departure)}, '
                '${DateFormat.Hm(locale).format(departure)}',
        detail: readyBy == null
            ? null
            : l10n.step3_readyBy(DateFormat.Hm(locale).format(readyBy)),
        step: _stepDateTime,
      ),
      _SummaryRow(
        label: l10n.summary_options,
        value: state.selectedOptions.isEmpty
            ? l10n.step5_noOptions
            : state.selectedOptions
                .map((o) => serviceOptionInfo(l10n, o).title)
                .join(', '),
        step: _stepOptions,
      ),
      if (state.snowDepthCm != null)
        _SummaryRow(
          label: l10n.summary_snow,
          value: snowRangeLabel(l10n, state.snowDepthCm),
          step: _stepOptions,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.border),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _parkingLabel(AppLocalizations l10n, NewReservationState state) {
    if (state.selectedParkingSpot != null) {
      return state.selectedParkingSpot!.fullDisplayName;
    }
    final spot = state.parkingSpotNumber;
    if (spot != null && spot.isNotEmpty) return l10n.summary_place(spot);
    final custom = state.customLocation;
    if (custom != null && custom.isNotEmpty) return custom;
    return '—';
  }

  Widget _buildFact(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Une ligne : libelle, valeur (et precision), lien pour revenir a l'etape.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final int step;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.step,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<NewReservationBloc>().add(GoToStep(step)),
            child: Text(
              l10n.step5_edit,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
