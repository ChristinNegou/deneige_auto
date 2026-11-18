import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/price_summary_card.dart';

/// Etape Options : options facultatives en liste lisible (les plus demandees
/// d'abord), quantite de neige en quelques choix, et total estime. Le detail
/// du prix est sur l'etape Recapitulatif.
class Step4OptionsScreen extends StatefulWidget {
  const Step4OptionsScreen({super.key});

  @override
  State<Step4OptionsScreen> createState() => _Step4OptionsScreenState();
}

/// Tranche de neige proposee, et la valeur envoyee au calcul du prix.
class _SnowRange {
  final String Function(AppLocalizations) label;
  final int? cm;
  final bool Function(int? cm) matches;
  const _SnowRange(this.label, this.cm, this.matches);
}

class _Step4OptionsScreenState extends State<Step4OptionsScreen> {
  static const _mainOptions = [
    ServiceOption.windowScraping,
    ServiceOption.doorDeicing,
    ServiceOption.wheelClearance,
  ];

  static const _moreOptions = [
    ServiceOption.roofClearing,
    ServiceOption.lightsCleaning,
    ServiceOption.saltSpreading,
    ServiceOption.perimeterClearance,
    ServiceOption.exhaustCheck,
  ];

  // Valeur au milieu de chaque tranche ; au-dela de 15 cm, souffleuse requise.
  static final _snowRanges = [
    _SnowRange((l) => l.snow_unknown, null, (cm) => cm == null),
    _SnowRange((l) => l.snow_under10, 5, (cm) => cm != null && cm < 10),
    _SnowRange(
        (l) => l.snow_10to20, 15, (cm) => cm != null && cm >= 10 && cm < 20),
    _SnowRange(
        (l) => l.snow_20to30, 25, (cm) => cm != null && cm >= 20 && cm < 30),
    _SnowRange((l) => l.snow_over30, 40, (cm) => cm != null && cm >= 30),
  ];

  late bool _showMore;

  @override
  void initState() {
    super.initState();
    // Une option secondaire deja cochee reste visible
    final selected = context.read<NewReservationBloc>().state.selectedOptions;
    _showMore = _moreOptions.any(selected.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NewReservationBloc, NewReservationState>(
      builder: (context, state) {
        final visible = [..._mainOptions, if (_showMore) ..._moreOptions];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.step4_additionalOptions, style: AppTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.step4_optionsHelp,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: AppTheme.border),
                      _OptionRow(
                        option: visible[i],
                        selected: state.selectedOptions.contains(visible[i]),
                        onTap: () => context
                            .read<NewReservationBloc>()
                            .add(ToggleServiceOption(visible[i])),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showMore = !_showMore),
                icon: Icon(
                  _showMore
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppTheme.primary,
                ),
                label: Text(
                  _showMore
                      ? l10n.step4_fewerOptions
                      : l10n.step4_moreOptions(_moreOptions.length),
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.step4_snowDepth, style: AppTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.step4_snowHelp,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final range in _snowRanges)
                    _SnowChip(
                      label: range.label(l10n),
                      selected: range.matches(state.snowDepthCm),
                      onTap: () => context
                          .read<NewReservationBloc>()
                          .add(UpdateSnowDepth(range.cm)),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const PriceSummaryCard(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _OptionRow extends StatelessWidget {
  final ServiceOption option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (String title, String description, IconData icon, double price) =
        switch (option) {
      ServiceOption.windowScraping => (
          l10n.option_windowScraping,
          l10n.option_windowScrapingDesc,
          Icons.cleaning_services_rounded,
          AppConfig.iceRemovalSurcharge,
        ),
      ServiceOption.doorDeicing => (
          l10n.option_doorDeicing,
          l10n.option_doorDeicingDesc,
          Icons.door_front_door_rounded,
          AppConfig.doorDeicingSurcharge,
        ),
      ServiceOption.wheelClearance => (
          l10n.option_wheelClearance,
          l10n.option_wheelClearanceDesc,
          Icons.tire_repair_rounded,
          AppConfig.wheelClearanceSurcharge,
        ),
      ServiceOption.roofClearing => (
          l10n.option_roofClearing,
          l10n.option_roofClearingDesc,
          Icons.directions_car_filled_rounded,
          AppConfig.roofClearingSurcharge,
        ),
      ServiceOption.saltSpreading => (
          l10n.option_saltSpreading,
          l10n.option_saltSpreadingDesc,
          Icons.grain_rounded,
          AppConfig.saltSpreadingSurcharge,
        ),
      ServiceOption.lightsCleaning => (
          l10n.option_lightsCleaning,
          l10n.option_lightsCleaningDesc,
          Icons.highlight_rounded,
          AppConfig.lightsCleaningSurcharge,
        ),
      ServiceOption.perimeterClearance => (
          l10n.option_perimeterClearance,
          l10n.option_perimeterClearanceDesc,
          Icons.crop_free_rounded,
          AppConfig.perimeterClearanceSurcharge,
        ),
      ServiceOption.exhaustCheck => (
          l10n.option_exhaustCheck,
          l10n.option_exhaustCheckDesc,
          Icons.air_rounded,
          AppConfig.exhaustCheckSurcharge,
        ),
    };

    return Semantics(
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '+${price.toStringAsFixed(0)} \$',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color:
                      selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 16, color: AppTheme.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnowChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SnowChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
                color: selected ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.onPrimary : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
