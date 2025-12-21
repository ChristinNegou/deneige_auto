import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_routes.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Balance Card
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF8B5CF6),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF7C3AED),
                      Color(0xFF6D28D9),
                    ],
                  ),
                ),
                child: _buildBalanceCard(),
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF8B5CF6),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF8B5CF6),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Historique'),
                  Tab(text: 'Méthodes'),
                  Tab(text: 'Statistiques'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
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
    );
  }

  Widget _buildBalanceCard() {
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solde total',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.totalSpent.toStringAsFixed(2)} \$',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('Transactions', state.transactionCount.toString()),
                  const SizedBox(width: 24),
                  _buildStatItem('Moyenne', '${state.averagePerTransaction.toStringAsFixed(2)} \$'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        if (state.isLoading && state.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory()),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state.filteredPayments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun paiement',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<PaymentHistoryBloc>().add(RefreshPaymentHistory());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(payment.status),
                    color: _getStatusColor(payment.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.displayDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy à HH:mm').format(payment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${payment.amount.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(payment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatusColor(payment.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (payment.methodType == PaymentMethodType.card && payment.last4 != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '•••• ${payment.last4}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return Colors.green;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Colors.blue;
      case PaymentStatus.canceled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return Icons.check_circle;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.refresh;
      case PaymentStatus.canceled:
        return Icons.cancel;
    }
  }

  Widget _buildMethodsTab() {
    return BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
      builder: (context, state) {
        if (state.isLoading && state.methods.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.methods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<PaymentMethodsBloc>().add(LoadPaymentMethods()),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...state.methods.map((method) => _buildPaymentMethodCard(method)),
            const SizedBox(height: 16),
            _buildAddPaymentMethodButton(),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.credit_card,
                color: Color(0xFF8B5CF6),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.brand.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (method.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Par défaut',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.displayNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expire ${method.expiryDisplay}',
                    style: TextStyle(
                      fontSize: 12,
                      color: method.isExpired ? Colors.red : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
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
                        Icon(Icons.star, size: 20),
                        SizedBox(width: 8),
                        Text('Définir par défaut'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la carte'),
        content: Text('Voulez-vous vraiment supprimer la carte ${method.displayNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PaymentMethodsBloc>().add(
                DeletePaymentMethod(method.stripePaymentMethodId!),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentMethodButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.addPaymentMethod,
        );

        // Reload payment methods if card was added
        if (result == true && mounted) {
          context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Ajouter une carte'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFF8B5CF6)),
        foregroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildStatsTab() {
    return BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Total dépensé',
              '${state.totalSpent.toStringAsFixed(2)} \$',
              Icons.monetization_on,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Nombre de transactions',
              state.transactionCount.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Montant moyen',
              '${state.averagePerTransaction.toStringAsFixed(2)} \$',
              Icons.analytics,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total remboursé',
              '${state.totalRefunded.toStringAsFixed(2)} \$',
              Icons.refresh,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
