import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/reservation_remote_datasource.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/usecases/cancel_reservation_usecase.dart';

/// Ouvre la feuille d'annulation. Renvoie le resultat du serveur si la
/// reservation a ete annulee, null si le client l'a gardee.
Future<CancellationResult?> showCancelReservationSheet(
  BuildContext context,
  Reservation reservation,
) {
  return showModalBottomSheet<CancellationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CancelReservationSheet(reservation: reservation),
  );
}

/// Annulation : ce que le client recupere, une raison facultative, puis la
/// confirmation. La feuille attend la reponse du serveur avant de se fermer.
class _CancelReservationSheet extends StatefulWidget {
  final Reservation reservation;

  const _CancelReservationSheet({required this.reservation});

  @override
  State<_CancelReservationSheet> createState() =>
      _CancelReservationSheetState();
}

class _CancelReservationSheetState extends State<_CancelReservationSheet> {
  String? _reason;
  bool _sending = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await sl<CancelReservationUseCase>()(
      widget.reservation.id,
      reason: _reason,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _sending = false;
        _error = failure.message;
      }),
      (cancellation) => Navigator.of(context).pop(cancellation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.cancel_reasonNotNeeded,
      l10n.cancel_reasonMistake,
      l10n.cancel_reasonDidItMyself,
      l10n.cancel_reasonOther,
    ];

    return PopScope(
      canPop: !_sending,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.cancel_title, style: AppTheme.headlineMedium),
              const SizedBox(height: 12),
              ..._buildRefundLines(context),
              const SizedBox(height: 20),
              Text(
                l10n.cancel_reasonLabel,
                style: AppTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in reasons)
                    _ReasonChip(
                      label: reason,
                      selected: _reason == reason,
                      onTap: _sending
                          ? null
                          : () => setState(() =>
                              _reason = _reason == reason ? null : reason),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style:
                            AppTheme.bodySmall.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: AppTheme.onPrimary,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.onPrimary),
                        )
                      : Text(l10n.cancel_confirm),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _sending ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel_keep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ce que le client recupere, selon l'avancement (regles du serveur).
  List<Widget> _buildRefundLines(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.reservation;
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';
    final money = NumberFormat.currency(locale: locale, symbol: '\$');
    final total = r.totalPrice;

    if (!r.isPaid) return [_line(l10n.cancel_notPaid)];

    switch (r.status) {
      case ReservationStatus.pending:
      case ReservationStatus.assigned:
        return [
          _line(l10n.cancel_refundFull(money.format(total)), strong: true),
          const SizedBox(height: 6),
          _line(l10n.cancel_refundDelay),
        ];
      case ReservationStatus.enRoute:
        final fee = total * 0.5;
        return [
          _line(
            l10n.cancel_refundPartial(
                money.format(fee), money.format(total - fee)),
            strong: true,
          ),
          const SizedBox(height: 6),
          _line(l10n.cancel_refundDelay),
        ];
      case ReservationStatus.inProgress:
        return [
          _line(l10n.cancel_refundNone(money.format(total)), strong: true),
        ];
      default:
        return const [];
    }
  }

  Widget _line(String text, {bool strong = false}) {
    return Text(
      text,
      style: strong
          ? AppTheme.bodyLarge.copyWith(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600)
          : AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ReasonChip({
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.onPrimary : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
