import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Ce que l'ecran de confirmation affiche de la reservation qui vient d'etre
/// payee. Seul l'identifiant est obligatoire.
class ReservationSuccessArgs {
  final String reservationId;
  final double? amount;
  final DateTime? departure;
  final DateTime? readyBy;
  final String? address;

  const ReservationSuccessArgs({
    required this.reservationId,
    this.amount,
    this.departure,
    this.readyBy,
    this.address,
  });
}

/// Confirmation sobre : la reservation est enregistree et payee, ses
/// informations cles, ce qui va se passer, puis les deux actions utiles.
class ReservationSuccessScreen extends StatelessWidget {
  final ReservationSuccessArgs args;

  const ReservationSuccessScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';
    final money = NumberFormat.currency(locale: locale, symbol: '\$');

    return PopScope(
      // Retour = accueil : le parcours de reservation est termine
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLG),
                        ),
                        child: Icon(Icons.check_rounded,
                            color: AppTheme.onPrimary, size: 32),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.reservationSuccess_title,
                          style: AppTheme.headlineLarge),
                      if (args.amount != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.reservationSuccess_paid(
                              money.format(args.amount)),
                          style: AppTheme.bodyLarge
                              .copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildDetails(context, l10n, locale),
                      const SizedBox(height: 28),
                      Text(l10n.reservationSuccess_nextSteps,
                          style: AppTheme.headlineSmall),
                      const SizedBox(height: 14),
                      // Une vraie sequence : numerotee
                      _buildStep(1, l10n.reservationSuccess_step1),
                      _buildStep(2, l10n.reservationSuccess_step2),
                      _buildStep(3, l10n.reservationSuccess_step3,
                          isLast: true),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.reservationDetails,
                          (route) => route.isFirst,
                          arguments: args.reservationId,
                        ),
                        child: Text(l10n.reservationSuccess_viewReservation),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _goHome(context),
                        child: Text(l10n.reservationSuccess_backToHome),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  Widget _buildDetails(
      BuildContext context, AppLocalizations l10n, String locale) {
    final departure = args.departure;
    final readyBy = args.readyBy;
    final rows = <(String, String)>[
      if (departure != null)
        (
          l10n.reservationSuccess_departure,
          '${DateFormat('EEEE d MMMM', locale).format(departure)}, '
              '${DateFormat.Hm(locale).format(departure)}',
        ),
      if (readyBy != null)
        (
          l10n.reservationSuccess_readyBy,
          DateFormat.Hm(locale).format(readyBy),
        ),
      if (args.address != null) (l10n.step5_address, args.address!),
      (
        l10n.reservationSuccess_reservationNumber,
        '#${_shortReference(args.reservationId)}',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      rows[i].$1,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
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

  /// Reference courte et lisible a partir de l'identifiant technique.
  String _shortReference(String id) {
    final clean = id.replaceAll('-', '');
    return (clean.length > 6 ? clean.substring(clean.length - 6) : clean)
        .toUpperCase();
  }

  Widget _buildStep(int number, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
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
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
