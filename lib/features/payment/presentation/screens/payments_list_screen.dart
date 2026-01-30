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
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory());
              context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
            },
            icon: Icon(Icons.refresh, color: AppTheme.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2,
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.payment_totalSpent,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.background.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.totalSpent.toStringAsFixed(2)} \$',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.background,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: AppTheme.background.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${state.transactionCount}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.background,
                      ),
                    ),
                    Text(
                      l10n.payment_transactions,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.background.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.filteredPayments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Icône statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(payment.status),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.displayDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormat('dd MMM, HH:mm').format(payment.createdAt),
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                    if (payment.last4 != null) ...[
                      Text(' · ',
                          style: TextStyle(color: AppTheme.textTertiary)),
                      Text(
                        '•••• ${payment.last4}',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Montant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(2)} \$',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
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
        return AppTheme.success;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return AppTheme.warning;
      case PaymentStatus.failed:
        return AppTheme.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return AppTheme.info;
      case PaymentStatus.canceled:
        return AppTheme.textTertiary;
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
          padding: const EdgeInsets.all(16),
          children: [
            if (state.methods.isEmpty)
              _buildEmptyMethodsMessage()
            else
              ...state.methods.map((method) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: method.isDefault
              ? AppTheme.success.withValues(alpha: 0.5)
              : AppTheme.border,
          width: method.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Logo carte
          Container(
            width: 44,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                method.brand.displayName.substring(
                    0,
                    method.brand.displayName.length > 4
                        ? 4
                        : method.brand.displayName.length),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Infos carte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.displayNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.common_default,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.payment_expires(method.expiryDisplay),
                  style: TextStyle(
                    fontSize: 12,
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
            icon: Icon(Icons.more_vert, color: AppTheme.textTertiary, size: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return GestureDetector(
      onTap: () async {
        final result =
            await Navigator.pushNamed(context, AppRoutes.addPaymentMethod);
        if (result == true && mounted) {
          context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.payment_addCard,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
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
