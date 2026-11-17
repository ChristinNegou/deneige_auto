import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_history_bloc.dart';
import '../bloc/payment_methods_bloc.dart';
import '../widgets/card_brand_mark.dart';
import 'package:intl/intl.dart';

class PaymentsListScreen extends StatelessWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PaymentHistoryBloc>()..add(LoadPaymentHistory()),
        ),
        BlocProvider(
          create: (_) => sl<PaymentMethodsBloc>()..add(LoadPaymentMethods()),
        ),
      ],
      child: const PaymentsListScreenContent(),
    );
  }
}

class PaymentsListScreenContent extends StatefulWidget {
  const PaymentsListScreenContent({super.key});

  @override
  State<PaymentsListScreenContent> createState() =>
      _PaymentsListScreenContentState();
}

class _PaymentsListScreenContentState extends State<PaymentsListScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.payment_payments),
        actions: [
          IconButton(
            onPressed: () {
              context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory());
              context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.payment_historyTab),
            Tab(text: l10n.payment_methodsTab),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _buildMethodsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.payment_totalSpent,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.totalSpent.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppTheme.onPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${state.transactionCount}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                  Text(
                    l10n.payment_transactions,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        if (state.isLoading && state.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.payments.isEmpty) {
          return _buildErrorState(
            state.errorMessage!,
            () =>
                context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory()),
          );
        }

        if (state.filteredPayments.isEmpty) {
          return _buildEmptyState(
            Icons.receipt_long_outlined,
            l10n.payment_noPayments,
            l10n.payment_transactionsAppearHere,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory());
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: state.filteredPayments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildPaymentItem(state.filteredPayments[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final statusColor = _getStatusColor(payment.status);
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en_CA'
        : 'fr_CA';
    final meta = [
      DateFormat('d MMM, HH:mm', locale).format(payment.createdAt),
      if (payment.last4 != null) '•••• ${payment.last4}',
    ].join('  ·  ');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(
              _getStatusIcon(payment.status),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.displayDescription,
                  style: AppTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(meta, style: AppTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(2)} \$',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(
                label: payment.status.displayName,
                color: statusColor,
                small: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return AppTheme.statusCompleted;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return AppTheme.statusPending;
      case PaymentStatus.failed:
        return AppTheme.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return AppTheme.info;
      case PaymentStatus.canceled:
        return AppTheme.statusCancelled;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return Icons.check_circle_outline;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error_outline;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.replay;
      case PaymentStatus.canceled:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildMethodsTab() {
    return BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
      builder: (context, state) {
        if (state.isLoading && state.methods.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.methods.isEmpty) {
          return _buildErrorState(
            state.errorMessage!,
            () => context.read<PaymentMethodsBloc>().add(LoadPaymentMethods()),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (state.methods.isEmpty)
              _buildEmptyMethodsMessage()
            else
              ...state.methods.map((method) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildMethodCard(method),
                  )),
            const SizedBox(height: 8),
            _buildAddCardButton(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMethodsMessage() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        children: [
          AppIllustration(
            type: IllustrationType.emptyPaymentMethods,
            width: 110,
            height: 110,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.payment_noCardsRegistered,
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.payment_addCardToFacilitate,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethod method) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Row(
        children: [
          CardBrandMark(brand: method.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.displayNumber,
                      style: AppTheme.labelLarge.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: l10n.common_default,
                        color: AppTheme.textSecondary,
                        small: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.payment_expires(method.expiryDisplay),
                  style: AppTheme.bodySmall.copyWith(
                    color: method.isExpired
                        ? AppTheme.error
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Menu actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded,
                color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
            onSelected: (value) {
              if (value == 'default') {
                context.read<PaymentMethodsBloc>().add(
                      SetDefaultPaymentMethod(method.stripePaymentMethodId!),
                    );
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, method);
              }
            },
            itemBuilder: (context) => [
              if (!method.isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Text(l10n.payment_setDefault),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.common_delete,
                    style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod method) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.payment_deleteCardTitle),
        content: Text(l10n.payment_deleteCardConfirm(method.displayNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PaymentMethodsBloc>().add(
                    DeletePaymentMethod(method.stripePaymentMethodId!),
                  );
            },
            child: Text(l10n.common_delete,
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton() {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () async {
        final result =
            await Navigator.pushNamed(context, AppRoutes.addPaymentMethod);
        if (result == true && mounted) {
          context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
        }
      },
      icon: const Icon(Icons.add_rounded),
      label: Text(l10n.payment_addCard),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIllustration(
            type: IllustrationType.emptyPaymentHistory,
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.common_retry),
          ),
        ],
      ),
    );
  }
}
