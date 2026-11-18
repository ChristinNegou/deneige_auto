import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../widgets/cancel_reservation_sheet.dart';
import '../widgets/service_option_info.dart';
import '../bloc/reservation_list_bloc.dart';
import '../../../widgets/rating_tip_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../disputes/presentation/pages/report_no_show_page.dart';
import '../../../disputes/presentation/pages/create_dispute_page.dart';

class ReservationDetailsPage extends StatelessWidget {
  final String reservationId;

  const ReservationDetailsPage({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ReservationListBloc>()..add(LoadReservationById(reservationId)),
      child: ReservationDetailsView(reservationId: reservationId),
    );
  }
}

/// Detail d'une reservation : ou elle en est, qui s'en occupe, ce qui a ete
/// commande et paye, puis les actions possibles a ce stade.
class ReservationDetailsView extends StatefulWidget {
  final String reservationId;

  const ReservationDetailsView({super.key, required this.reservationId});

  @override
  State<ReservationDetailsView> createState() => _ReservationDetailsViewState();
}

class _ReservationDetailsViewState extends State<ReservationDetailsView> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Rafraichit le statut toutes les 15 s tant que la reservation est active
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final reservation =
          context.read<ReservationListBloc>().state.selectedReservation;
      if (reservation != null && _isActive(reservation.status)) {
        _reload();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isActive(ReservationStatus status) =>
      status == ReservationStatus.pending ||
      status == ReservationStatus.assigned ||
      status == ReservationStatus.enRoute ||
      status == ReservationStatus.inProgress;

  void _reload() => context
      .read<ReservationListBloc>()
      .add(LoadReservationById(widget.reservationId));

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en_CA' : 'fr_CA';

  String _money(double amount) =>
      NumberFormat.currency(locale: _locale, symbol: '\$').format(amount);

  /// Confirmation sobre (encre marine), ou erreur en rouge.
  void _notify(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: AppTheme.onPrimary)),
        backgroundColor: error ? AppTheme.error : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ReservationListBloc, ReservationListState>(
      builder: (context, state) {
        final reservation = state.selectedReservation;

        if (state.isLoading && reservation == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title:
                  Text(l10n.reservation_details, style: AppTheme.labelMedium),
              centerTitle: true,
            ),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (reservation == null) return _buildNotFound(context);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.reservation_details, style: AppTheme.labelMedium),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _buildStatus(context, reservation),
                const SizedBox(height: 20),
                if (reservation.workerId != null) ...[
                  _buildWorkerCard(context, reservation),
                  const SizedBox(height: 16),
                ],
                _buildDetails(context, reservation),
                if (reservation.afterPhotoUrl != null ||
                    reservation.beforePhotoUrl != null) ...[
                  const SizedBox(height: 16),
                  _buildPhotos(context, reservation),
                ],
                if (reservation.status == ReservationStatus.completed) ...[
                  const SizedBox(height: 16),
                  _buildRating(context, reservation),
                ],
                const SizedBox(height: 24),
                ..._buildActions(context, reservation),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotFound(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.reservation_details, style: AppTheme.labelMedium),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(l10n.reservation_notFound, style: AppTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                l10n.reservation_notFoundSubtitle,
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _reload,
                child: Text(l10n.reservation_refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Statut et progression ---

  Widget _buildStatus(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(reservation.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(label: reservation.status.displayName, color: color),
        const SizedBox(height: 12),
        Text(_statusSentence(l10n, reservation), style: AppTheme.headlineLarge),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEEE d MMMM, HH:mm', _locale)
              .format(reservation.departureTime),
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        _buildProgress(context, reservation),
      ],
    );
  }

  String _statusSentence(AppLocalizations l10n, Reservation reservation) {
    switch (reservation.status) {
      case ReservationStatus.pending:
        return l10n.reservation_statusPending;
      case ReservationStatus.assigned:
        return l10n.reservation_statusAssigned;
      case ReservationStatus.enRoute:
        return l10n.reservation_statusEnRoute(
            reservation.workerName ?? l10n.reservation_yourWorker);
      case ReservationStatus.inProgress:
        return l10n.reservation_statusInProgress;
      case ReservationStatus.completed:
        return l10n.reservation_statusCompleted;
      case ReservationStatus.cancelled:
        return l10n.reservation_statusCancelled;
      case ReservationStatus.late:
        return l10n.reservation_statusDelayed;
    }
  }

  /// Barre d'avancement en 5 etapes, sans carte autour.
  Widget _buildProgress(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    const steps = [
      ReservationStatus.pending,
      ReservationStatus.assigned,
      ReservationStatus.enRoute,
      ReservationStatus.inProgress,
      ReservationStatus.completed,
    ];
    final current = steps.indexOf(reservation.status);
    // Annulee ou en retard : hors du parcours normal
    if (current < 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin:
                        EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i < current
                          ? AppTheme.primary
                          : i == current
                              ? _statusColor(reservation.status)
                              : AppTheme.border,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Text(
                    _shortStatus(l10n, steps[i]),
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight:
                          i == current ? FontWeight.w800 : FontWeight.w600,
                      color: i == current
                          ? AppTheme.textPrimary
                          : i < current
                              ? AppTheme.textSecondary
                              : AppTheme.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortStatus(AppLocalizations l10n, ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return l10n.reservation_shortPending;
      case ReservationStatus.assigned:
        return l10n.reservation_shortAssigned;
      case ReservationStatus.enRoute:
        return l10n.reservation_shortEnRoute;
      case ReservationStatus.inProgress:
        return l10n.reservation_shortInProgress;
      case ReservationStatus.completed:
        return l10n.reservation_shortCompleted;
      case ReservationStatus.cancelled:
        return l10n.reservation_shortCancelled;
      case ReservationStatus.late:
        return l10n.reservation_shortDelayed;
    }
  }

  Color _statusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppTheme.statusPending;
      case ReservationStatus.assigned:
        return AppTheme.statusAssigned;
      case ReservationStatus.enRoute:
        return AppTheme.statusEnRoute;
      case ReservationStatus.inProgress:
        return AppTheme.statusInProgress;
      case ReservationStatus.completed:
        return AppTheme.statusCompleted;
      case ReservationStatus.cancelled:
        return AppTheme.statusCancelled;
      case ReservationStatus.late:
        return AppTheme.error;
    }
  }

  // --- Deneigeur ---

  Widget _buildWorkerCard(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final initial = reservation.workerName?.isNotEmpty == true
        ? reservation.workerName![0].toUpperCase()
        : '?';
    final initialAvatar = Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppTheme.onPrimary,
        ),
      ),
    );

    return _Section(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: reservation.workerPhotoUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: reservation.workerPhotoUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      placeholder: (_, __) => initialAvatar,
                      errorWidget: (_, __, ___) => initialAvatar,
                    )
                  : initialAvatar,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reservation_yourWorker,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reservation.workerName ??
                            l10n.reservation_workerAssigned,
                        style: AppTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (reservation.workerIsVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded,
                          color: AppTheme.info,
                          size: 16,
                          semanticLabel: l10n.worker_verified),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: l10n.reservation_chat,
            onPressed: () => _openChat(context, reservation),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceContainer,
              foregroundColor: AppTheme.textPrimary,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          ),
          if (reservation.workerPhone != null)
            IconButton.filledTonal(
              tooltip: l10n.common_call,
              onPressed: () => _callWorker(reservation),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainer,
                foregroundColor: AppTheme.textPrimary,
              ),
              icon: const Icon(Icons.phone_outlined, size: 20),
            ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _notify(l10n.reservation_userNotAuth, error: true);
      return;
    }
    if (reservation.workerId == null) {
      _notify(l10n.reservation_noWorkerYet);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<ChatBloc>()..add(LoadMessages(reservation.id)),
          child: ChatScreen(
            reservationId: reservation.id,
            otherUserName:
                reservation.workerName ?? l10n.reservation_workerAssigned,
            otherUserPhoto: null,
            currentUserId: authState.user.id,
          ),
        ),
      ),
    );
  }

  Future<void> _callWorker(Reservation reservation) async {
    final phone = reservation.workerPhone;
    if (phone == null) {
      _notify(AppLocalizations.of(context)!.reservation_phoneUnavailable);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // --- Details de la commande ---

  Widget _buildDetails(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final timeFmt = DateFormat.Hm(_locale);
    final dateTimeFmt = DateFormat('d MMM, HH:mm', _locale);
    final vehicle = reservation.vehicle;

    final rows = <(String, String, String?)>[
      (
        l10n.reservation_vehicle,
        vehicle.displayName,
        [vehicle.color, vehicle.licensePlate]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' · '),
      ),
      (l10n.reservation_location, reservation.parkingSpot.displayName, null),
      if (reservation.locationAddress != null)
        (l10n.common_address, reservation.locationAddress!, null),
      (
        l10n.details_departure,
        DateFormat('EEE d MMM, HH:mm', _locale)
            .format(reservation.departureTime),
        reservation.deadlineTime == null
            ? null
            : l10n.step3_readyBy(timeFmt.format(reservation.deadlineTime!)),
      ),
      (
        l10n.summary_options,
        reservation.serviceOptions.isEmpty
            ? l10n.step5_noOptions
            : reservation.serviceOptions
                .map((o) => serviceOptionInfo(l10n, o).title)
                .join(', '),
        null,
      ),
      if (reservation.snowDepthCm != null)
        (
          l10n.summary_snow,
          snowRangeLabel(l10n, reservation.snowDepthCm),
          null,
        ),
      (
        reservation.isPaid ? l10n.edit_paidPrice : l10n.reservation_totalPrice,
        _money(reservation.totalPrice),
        reservation.tip != null && reservation.tip! > 0
            ? l10n.reservation_tipAmount(reservation.tip!.toStringAsFixed(2))
            : null,
      ),
    ];

    final history = <(String, DateTime)>[
      if (reservation.assignedAt != null)
        (l10n.reservation_assignedAt, reservation.assignedAt!),
      if (reservation.startedAt != null)
        (l10n.reservation_startedAt, reservation.startedAt!),
      if (reservation.completedAt != null)
        (l10n.reservation_completedAt, reservation.completedAt!),
    ];

    return _Section(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppTheme.border),
            _DetailRow(
                label: rows[i].$1, value: rows[i].$2, detail: rows[i].$3),
          ],
          if (history.isNotEmpty) ...[
            Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.details_history,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  for (final (label, date) in history)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(label,
                                style: AppTheme.bodyMedium
                                    .copyWith(color: AppTheme.textPrimary)),
                          ),
                          Text(
                            dateTimeFmt.format(date),
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
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

  // --- Photos ---

  Widget _buildPhotos(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    final photos = [
      if (reservation.beforePhotoUrl != null)
        (l10n.reservation_beforePhoto, reservation.beforePhotoUrl!),
      if (reservation.afterPhotoUrl != null)
        (l10n.reservation_afterPhoto, reservation.afterPhotoUrl!),
    ];

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reservation_photos, style: AppTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < photos.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _PhotoTile(
                    label: photos[i].$1,
                    url: photos[i].$2,
                    onTap: () => _showPhotoFullscreen(
                        context, photos[i].$2, photos[i].$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showPhotoFullscreen(
      BuildContext context, String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Evaluation ---

  Widget _buildRating(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;

    if (reservation.rating != null) {
      return _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reservation_yourRating,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < reservation.rating!.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppTheme.warning,
                  size: 22,
                ),
              ),
            ),
            if (reservation.review?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                '« ${reservation.review} »',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      );
    }

    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: () => _openRating(context, reservation),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.star_outline_rounded,
                  color: AppTheme.warning, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.reservation_rateService,
                        style: AppTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(l10n.reservation_rateSubtitle,
                        style: AppTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _openRating(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    RatingTipDialog.show(
      context,
      workerName: reservation.workerName ?? l10n.reservation_workerAssigned,
      servicePrice: reservation.totalPrice,
      onSubmit: (rating, tip, comment) async {
        final repository = sl<ReservationRepository>();
        final ratingResult = await repository.rateReservation(
          reservationId: reservation.id,
          rating: rating,
          review: comment,
        );

        await ratingResult.fold(
          (failure) async =>
              _notify(l10n.resDetail_errorPrefix(failure.message), error: true),
          (_) async {
            if (tip != null && tip > 0) {
              final tipResult = await repository.addTip(
                reservationId: reservation.id,
                amount: tip,
              );
              tipResult.fold(
                (failure) => _notify(
                    l10n.resDetail_ratingSuccessTipError(failure.message),
                    error: true),
                (_) => _notify(l10n.resDetail_tipSent(tip.toStringAsFixed(0))),
              );
            } else {
              _notify(l10n.resDetail_ratingSuccess);
            }
            // La note apparait sur la page, sans la quitter
            _reload();
          },
        );
      },
    );
  }

  // --- Actions ---

  List<Widget> _buildActions(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (reservation.canBeEdited) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final changed = await Navigator.pushNamed(
                context,
                AppRoutes.editReservation,
                arguments: reservation,
              );
              if (changed == true) _reload();
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.reservation_edit),
          ),
        ),
        const SizedBox(height: 4),
      ],
      if (reservation.canBeCancelled)
        Center(
          child: TextButton(
            onPressed: () => _cancel(context, reservation),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(l10n.reservation_cancelReservation,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      if (_canReportNoShow(reservation))
        _LinkRow(
          icon: Icons.person_off_outlined,
          label: l10n.details_noShowLink,
          onTap: () => _report(
            context,
            ReportNoShowPage(
              reservationId: reservation.id,
              workerName: reservation.workerName,
              totalPrice: reservation.totalPrice,
              departureTime: reservation.departureTime,
            ),
            l10n.reservation_noShowReported,
          ),
        ),
      if (_canReportProblem(reservation))
        _LinkRow(
          icon: Icons.flag_outlined,
          label: l10n.details_problemLink,
          onTap: () => _report(
            context,
            CreateDisputePage(
              reservationId: reservation.id,
              workerName: reservation.workerName,
              totalPrice: reservation.totalPrice,
              serviceDate: reservation.completedAt ?? reservation.departureTime,
            ),
            l10n.dispute_created,
          ),
        ),
    ];
  }

  Future<void> _cancel(BuildContext context, Reservation reservation) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();

    final result = await showCancelReservationSheet(context, reservation);
    if (result == null || !context.mounted) return;

    final refund = result.refundAmount;
    _notify(
        refund > 0 ? l10n.cancel_doneRefund(_money(refund)) : l10n.cancel_done);
    // true : l'ecran precedent recharge ses reservations
    Navigator.of(context).pop(true);
  }

  Future<void> _report(
      BuildContext context, Widget page, String doneMessage) async {
    HapticFeedback.mediumImpact();
    final reported = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (reported == true && mounted) {
      _reload();
      _notify(doneMessage);
    }
  }

  /// Absence signalable 30 min apres l'heure prevue, ou dans les 24 h qui
  /// suivent un travail marque termine.
  bool _canReportNoShow(Reservation reservation) {
    if (reservation.status == ReservationStatus.cancelled ||
        reservation.workerId == null) {
      return false;
    }
    final now = DateTime.now();
    if (reservation.status == ReservationStatus.completed) {
      final completedAt = reservation.completedAt;
      return completedAt != null && now.difference(completedAt).inHours < 24;
    }
    if (reservation.status == ReservationStatus.assigned ||
        reservation.status == ReservationStatus.enRoute ||
        reservation.status == ReservationStatus.late) {
      return now
          .isAfter(reservation.departureTime.add(const Duration(minutes: 30)));
    }
    return false;
  }

  /// Probleme signalable pendant le travail, ou dans les 72 h qui suivent.
  bool _canReportProblem(Reservation reservation) {
    if (reservation.status == ReservationStatus.cancelled ||
        reservation.workerId == null) {
      return false;
    }
    if (reservation.status == ReservationStatus.completed) {
      final completedAt = reservation.completedAt;
      return completedAt != null &&
          DateTime.now().difference(completedAt).inHours < 72;
    }
    return reservation.status == ReservationStatus.inProgress ||
        reservation.status == ReservationStatus.late;
  }
}

/// Carte blanche bordee, commune aux blocs de la page.
class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Section({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;

  const _DetailRow({required this.label, required this.value, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (detail != null && detail!.isNotEmpty)
            Text(detail!,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String label;
  final String url;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.label,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    ColoredBox(color: AppTheme.surfaceContainer),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: AppTheme.surfaceContainer,
                  child: Icon(Icons.broken_image_outlined,
                      color: AppTheme.textTertiary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }
}

/// Action secondaire en lien discret (signalements).
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTheme.labelLarge)),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
