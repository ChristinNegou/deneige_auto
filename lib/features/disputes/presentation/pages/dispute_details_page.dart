import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Detail d'un litige, vu par le client ou par le deneigeur : ou il en est,
/// la plainte, la reponse, la decision, et ce que chacun peut faire.
class DisputeDetailsPage extends StatefulWidget {
  final String disputeId;

  const DisputeDetailsPage({super.key, required this.disputeId});

  @override
  State<DisputeDetailsPage> createState() => _DisputeDetailsPageState();
}

class _DisputeDetailsPageState extends State<DisputeDetailsPage> {
  late final DisputeService _disputeService;
  Dispute? _dispute;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
    _loadDispute();
  }

  String? get _currentUserId {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user.id : null;
  }

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en_CA' : 'fr_CA';

  String _date(DateTime date) =>
      DateFormat('EEEE d MMMM, HH:mm', _locale).format(date.toLocal());

  String _money(num amount) =>
      NumberFormat.currency(locale: _locale, symbol: '\$').format(amount);

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

  Future<void> _loadDispute() async {
    setState(() {
      _isLoading = _dispute == null;
      _errorMessage = null;
    });
    try {
      final dispute = await _disputeService.getDisputeDetails(widget.disputeId);
      if (!mounted) return;
      setState(() {
        _dispute = dispute;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = disputeErrorMessage(
            e, AppLocalizations.of(context)!.common_errorOccurred);
        _isLoading = false;
      });
    }
  }

  // --- Actions ---

  Future<void> _openRespond() async {
    final dispute = _dispute!;
    final sent = await Navigator.pushNamed(
      context,
      AppRoutes.respondDispute,
      arguments: {
        'disputeId': widget.disputeId,
        'disputeType': dispute.type.label,
        'disputeDescription': dispute.description,
        'responseDeadline': dispute.responseDeadline?.toIso8601String(),
      },
    );
    if (sent == true) _loadDispute();
  }

  Future<void> _openAddEvidence() async {
    final added = await Navigator.pushNamed(
      context,
      AppRoutes.addEvidence,
      arguments: {
        'disputeId': widget.disputeId,
        'disputeStatus': _dispute!.status.value,
      },
    );
    if (added == true) _loadDispute();
  }

  Future<void> _appeal() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _AppealDialog(),
    );
    if (reason == null) return;
    try {
      await _disputeService.appealDispute(
          disputeId: widget.disputeId, reason: reason);
      _notify(l10n.dispute_appealSubmitted);
      _loadDispute();
    } catch (e) {
      _notify(disputeErrorMessage(e, l10n.dispute_cannotSendResponseRetry),
          error: true);
    }
  }

  void _showPhotos(List<DisputePhoto> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photos.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  photos[i].url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Page ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.dispute_details, style: AppTheme.labelMedium),
        centerTitle: true,
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _dispute == null
              ? _buildProblem(l10n)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadDispute,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: _buildContent(l10n, _dispute!),
                  ),
                ),
    );
  }

  List<Widget> _buildContent(AppLocalizations l10n, Dispute d) {
    final me = _currentUserId;
    final iAmRespondent = d.isRespondent(me);
    final mustRespond = iAmRespondent && d.canRespond && !d.hasResponse;
    final deadline = d.responseDeadline;
    final deadlinePassed = deadline != null && DateTime.now().isAfter(deadline);

    return [
      // Statut
      StatusBadge(label: d.status.label, color: _statusColor(d.status)),
      const SizedBox(height: 12),
      Text(d.type.label, style: AppTheme.headlineLarge),
      const SizedBox(height: 4),
      Text(l10n.disputeD_openedOn(_date(d.createdAt)),
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),

      // Ce qu'on attend du deneigeur, en premier
      if (mustRespond) ...[
        const SizedBox(height: 20),
        _Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deadlinePassed || deadline == null
                    ? (deadlinePassed ? l10n.disputeD_yourTurnLate : '')
                    : l10n.disputeD_yourTurn(_date(deadline)),
                style: AppTheme.bodyMedium.copyWith(
                  color: deadlinePassed ? AppTheme.error : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!deadlinePassed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openRespond,
                    icon: const Icon(Icons.reply_rounded),
                    label: Text(l10n.dispute_respond),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],

      const SizedBox(height: 20),
      _buildComplaint(l10n, d),
      const SizedBox(height: 16),
      _buildResponse(l10n, d, iAmRespondent),
      const SizedBox(height: 16),
      _buildDecision(l10n, d, me),
      const SizedBox(height: 20),
      ..._buildActions(l10n, d),
    ];
  }

  Widget _buildComplaint(AppLocalizations l10n, Dispute d) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.disputeD_complaint, style: AppTheme.headlineSmall),
          if (d.claimantName != null) ...[
            const SizedBox(height: 2),
            Text(l10n.disputeD_filedBy(d.claimantName!),
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 10),
          Text(d.description,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppTheme.textPrimary, height: 1.4)),
          if (d.claimedAmount > 0) ...[
            const SizedBox(height: 10),
            Text(l10n.disputeD_claimed(_money(d.claimedAmount)),
                style: AppTheme.labelLarge),
          ],
          if (d.evidencePhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PhotoStrip(
              photos: d.evidencePhotos,
              onTap: (i) => _showPhotos(d.evidencePhotos, i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponse(AppLocalizations l10n, Dispute d, bool iAmRespondent) {
    final text = d.response?['text'] as String?;
    final submittedAt = d.response?['submittedAt'] as String?;
    final deadline = d.responseDeadline;

    final String? waiting;
    if (text != null) {
      waiting = null;
    } else if (!d.canRespond) {
      waiting = l10n.disputeD_noResponse;
    } else if (!iAmRespondent && deadline != null) {
      waiting = l10n.disputeD_waitingResponse(_date(deadline));
    } else {
      waiting = null;
    }

    // Rien a montrer : le deneigeur voit deja son encadre "a repondre"
    if (text == null && waiting == null && d.responsePhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.disputeD_response, style: AppTheme.headlineSmall),
          const SizedBox(height: 10),
          if (text != null) ...[
            Text(text,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.textPrimary, height: 1.4)),
            if (submittedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.dispute_submittedOn(_date(DateTime.parse(submittedAt))),
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ] else if (waiting != null)
            Text(waiting,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.textSecondary)),
          if (d.responsePhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PhotoStrip(
              photos: d.responsePhotos,
              onTap: (i) => _showPhotos(d.responsePhotos, i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecision(AppLocalizations l10n, Dispute d, String? me) {
    final resolution = d.resolution;
    final decision = resolution?['decision'] as String?;

    if (decision == null) {
      // Les deux versions sont la : l'equipe tranche
      if (d.status == DisputeStatus.underReview ||
          d.status == DisputeStatus.appealed ||
          d.status == DisputeStatus.escalated) {
        return _Section(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hourglass_top_rounded,
                  size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.disputeD_underReview,
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary)),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final refund = resolution?['refundAmount'] as num?;
    final notes = resolution?['notes'] as String?;
    final resolvedAt = resolution?['resolvedAt'] as String?;

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dispute_decision, style: AppTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(_decisionLabel(l10n, decision, d, me),
              style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          if (refund != null && refund > 0) ...[
            const SizedBox(height: 4),
            Text(l10n.disputeD_refund(_money(refund)),
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary)),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(notes,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.textSecondary, height: 1.4)),
          ],
          if (resolvedAt != null) ...[
            const SizedBox(height: 8),
            Text(l10n.dispute_resolvedOn(_date(DateTime.parse(resolvedAt))),
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }

  /// "En votre faveur" depend de qui regarde : plaignant ou defendeur.
  String _decisionLabel(
      AppLocalizations l10n, String decision, Dispute d, String? me) {
    switch (decision) {
      case 'favor_claimant':
        return d.isClaimant(me)
            ? l10n.disputeD_forYou
            : l10n.disputeD_againstYou;
      case 'favor_respondent':
        return d.isRespondent(me)
            ? l10n.disputeD_forYou
            : l10n.disputeD_againstYou;
      case 'partial_refund':
        return l10n.dispute_decisionPartialRefund;
      case 'full_refund':
        return l10n.dispute_decisionFullRefund;
      case 'no_action':
        return l10n.dispute_decisionNoAction;
      case 'mutual_agreement':
        return l10n.dispute_decisionMutualAgreement;
      default:
        return decision;
    }
  }

  List<Widget> _buildActions(AppLocalizations l10n, Dispute d) {
    return [
      if (d.isOpen)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openAddEvidence,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(l10n.dispute_addEvidence),
          ),
        ),
      if (d.canAppeal)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _appeal,
            icon: const Icon(Icons.gavel_rounded),
            label: Text(l10n.dispute_appeal),
          ),
        ),
    ];
  }

  Widget _buildProblem(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                color: AppTheme.textTertiary, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage == null ? l10n.dispute_notFound : l10n.common_error,
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.dispute_notFoundMessage,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadDispute,
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
      case DisputeStatus.pendingResponse:
        return AppTheme.statusPending;
      case DisputeStatus.underReview:
      case DisputeStatus.appealed:
        return AppTheme.statusAssigned;
      case DisputeStatus.resolved:
        return AppTheme.statusCompleted;
      case DisputeStatus.closed:
        return AppTheme.statusCancelled;
      case DisputeStatus.escalated:
        return AppTheme.error;
    }
  }
}

/// Appel : la justification (50 caracteres minimum, comme le serveur).
class _AppealDialog extends StatefulWidget {
  const _AppealDialog();

  @override
  State<_AppealDialog> createState() => _AppealDialogState();
}

class _AppealDialogState extends State<_AppealDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final length = _controller.text.trim().length;
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(l10n.dispute_appeal),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dispute_appealExplanation,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: l10n.dispute_appealJustificationHint,
              counterText:
                  length < 50 ? l10n.disputeR_minChars(50, length) : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: length >= 50
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          child: Text(l10n.dispute_submitAppeal),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;

  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}

/// Vignettes cliquables des photos d'une partie.
class _PhotoStrip extends StatelessWidget {
  final List<DisputePhoto> photos;
  final ValueChanged<int> onTap;

  const _PhotoStrip({required this.photos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: Image.network(
              photos[i].url,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 84,
                height: 84,
                color: AppTheme.surfaceContainer,
                child: Icon(Icons.broken_image_outlined,
                    color: AppTheme.textTertiary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
