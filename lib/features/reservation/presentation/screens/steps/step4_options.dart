import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';
import '../../widgets/price_summary_card.dart';
import '../../widgets/service_option_info.dart';

/// Etape Options : options facultatives en liste lisible (les plus demandees
/// d'abord), quantite de neige en quelques choix, et total estime. Le detail
/// du prix est sur l'etape Recapitulatif.
class Step4OptionsScreen extends StatefulWidget {
  const Step4OptionsScreen({super.key});

  @override
  State<Step4OptionsScreen> createState() => _Step4OptionsScreenState();
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
                  for (final range in snowRanges)
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
    final (:title, :description, :icon, :price) =
        serviceOptionInfo(l10n, option);

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
