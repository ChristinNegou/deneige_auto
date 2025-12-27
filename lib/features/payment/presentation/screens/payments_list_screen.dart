import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
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
  State<PaymentsListScreenContent> createState() => _PaymentsListScreenContentState();
}

class _PaymentsListScreenContentState extends State<PaymentsListScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildMethodsTab(),
                  _buildStatsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                boxShadow: AppTheme.shadowSM,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Paiements',
            style: AppTheme.headlineMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory());
              context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total dépensé',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${state.totalSpent.toStringAsFixed(2)} \$',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      Icons.receipt_long_rounded,
                      state.transactionCount.toString(),
                      'Transactions',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildMiniStat(
                      Icons.trending_up_rounded,
                      '${state.averagePerTransaction.toStringAsFixed(0)} \$',
                      'Moyenne',
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

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Historique'),
          Tab(text: 'Méthodes'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        if (state.isLoading && state.payments.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state.errorMessage != null && state.payments.isEmpty) {
          return _buildErrorState(
            state.errorMessage!,
            () => context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory()),
          );
        }

        if (state.filteredPayments.isEmpty) {
          return _buildEmptyState(
            Icons.receipt_long_rounded,
            'Aucun paiement',
            'Vos transactions apparaîtront ici',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory());
          },
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingLG),
            itemCount: state.filteredPayments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(state.filteredPayments[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final statusColor = _getStatusColor(payment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(
                  _getStatusIcon(payment.status),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.displayDescription,
                      style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy à HH:mm').format(payment.createdAt),
                      style: AppTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment.amount.toStringAsFixed(2)} \$',
                    style: AppTheme.headlineSmall,
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
          if (payment.methodType == PaymentMethodType.card && payment.last4 != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.credit_card_rounded, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '•••• ${payment.last4}',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ],
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
        return Icons.check_circle_rounded;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Icons.schedule_rounded;
      case PaymentStatus.failed:
        return Icons.error_rounded;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.refresh_rounded;
      case PaymentStatus.canceled:
        return Icons.cancel_rounded;
    }
  }

  Widget _buildMethodsTab() {
    return BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
      builder: (context, state) {
        if (state.isLoading && state.methods.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (state.errorMessage != null && state.methods.isEmpty) {
          return _buildErrorState(
            state.errorMessage!,
            () => context.read<PaymentMethodsBloc>().add(LoadPaymentMethods()),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppTheme.paddingLG),
          children: [
            ...state.methods.map((method) => _buildPaymentMethodCard(method)),
            const SizedBox(height: 8),
            _buildAddPaymentMethodButton(),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: method.isDefault
            ? Border.all(color: AppTheme.success.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: AppTheme.shadowSM,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.brand.displayName,
                      style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'Par défaut',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  method.displayNumber,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Expire ${method.expiryDisplay}',
                  style: AppTheme.labelSmall.copyWith(
                    color: method.isExpired ? AppTheme.error : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
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
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 20, color: AppTheme.warning),
                      SizedBox(width: 8),
                      Text('Définir par défaut'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: const Text('Supprimer la carte'),
        content: Text('Voulez-vous vraiment supprimer la carte ${method.displayNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PaymentMethodsBloc>().add(
                DeletePaymentMethod(method.stripePaymentMethodId!),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentMethodButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.addPaymentMethod,
        );
        if (result == true && mounted) {
          context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ajouter une carte',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(AppTheme.paddingLG),
          children: [
            _buildStatCard(
              'Total dépensé',
              '${state.totalSpent.toStringAsFixed(2)} \$',
              Icons.monetization_on_rounded,
              AppTheme.success,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Nombre de transactions',
              state.transactionCount.toString(),
              Icons.receipt_long_rounded,
              AppTheme.primary,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Montant moyen',
              '${state.averagePerTransaction.toStringAsFixed(2)} \$',
              Icons.analytics_rounded,
              AppTheme.warning,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total remboursé',
              '${state.totalRefunded.toStringAsFixed(2)} \$',
              Icons.refresh_rounded,
              AppTheme.secondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.headlineMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(icon, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
