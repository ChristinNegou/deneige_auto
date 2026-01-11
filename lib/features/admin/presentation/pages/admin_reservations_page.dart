import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_reservation.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadReservations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des réservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminBloc>().add(LoadReservations(
                  status: _selectedStatus,
                )),
          ),
        ],
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppTheme.success,
              ),
            );
            context.read<AdminBloc>().add(ClearError());
          }
          if (state.errorMessage != null &&
              state.actionStatus == AdminStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.error,
              ),
            );
            context.read<AdminBloc>().add(ClearError());
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildStatusFilters(context),
              Expanded(child: _buildReservationsList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip(context, 'Toutes', null),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, 'En attente', 'pending', AppTheme.warning),
            const SizedBox(width: 8),
            _buildStatusChip(context, 'Assignées', 'assigned', AppTheme.info),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, 'En cours', 'inProgress', AppTheme.primary2),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, 'Terminées', 'completed', AppTheme.success),
            const SizedBox(width: 8),
            _buildStatusChip(context, 'Annulées', 'cancelled', AppTheme.error),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, String? status,
      [Color? color]) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = selected ? status : null);
        context.read<AdminBloc>().add(LoadReservations(
              status: selected ? status : null,
            ));
      },
      selectedColor: (color ?? AppTheme.primary).withValues(alpha: 0.2),
      checkmarkColor: color ?? AppTheme.primary,
      avatar: color != null
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _buildReservationsList(BuildContext context, AdminState state) {
    if (state.reservationsStatus == AdminStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.reservationsStatus == AdminStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'Une erreur est survenue'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AdminBloc>().add(LoadReservations()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: AppTheme.textTertiary),
            SizedBox(height: 16),
            Text('Aucune réservation trouvée'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<AdminBloc>()
            .add(LoadReservations(status: _selectedStatus));
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.reservations.length,
              itemBuilder: (context, index) {
                final reservation = state.reservations[index];
                return _buildReservationCard(context, reservation);
              },
            ),
          ),
          if (state.reservationsTotalPages > 1)
            _buildPagination(context, state),
        ],
      ),
    );
  }

  Widget _buildReservationCard(
      BuildContext context, AdminReservation reservation) {
    final statusColor = _getStatusColor(reservation.status);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReservationDetails(context, reservation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reservation.statusDisplay,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(reservation.departureTime),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (reservation.client != null)
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.client!.fullName,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              if (reservation.worker != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.ac_unit, size: 16, color: AppTheme.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.worker!.fullName,
                        style: TextStyle(color: AppTheme.info),
                      ),
                    ),
                  ],
                ),
              ],
              if (reservation.vehicle != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.directions_car,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.vehicle!.displayName,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (reservation.canRefund)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Rembourser'),
                        onPressed: () =>
                            _showRefundDialog(context, reservation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning,
                        ),
                      ),
                    ),
                  if (reservation.canRefund) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Détails'),
                      onPressed: () =>
                          _showReservationDetails(context, reservation),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'assigned':
        return AppTheme.info;
      case 'enRoute':
        return AppTheme.primary2;
      case 'inProgress':
        return AppTheme.primary2;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textTertiary;
    }
  }

  Widget _buildPagination(BuildContext context, AdminState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.reservationsPage > 1
                ? () {
                    context.read<AdminBloc>().add(LoadReservations(
                          page: state.reservationsPage - 1,
                          status: _selectedStatus,
                        ));
                  }
                : null,
          ),
          Text(
            'Page ${state.reservationsPage} / ${state.reservationsTotalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.reservationsPage < state.reservationsTotalPages
                ? () {
                    context.read<AdminBloc>().add(LoadReservations(
                          page: state.reservationsPage + 1,
                          status: _selectedStatus,
                        ));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showReservationDetails(
      BuildContext context, AdminReservation reservation) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _getStatusColor(reservation.status);
    final pageContext = context; // Capture avant le shadowing

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (scrollContext, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reservation.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${reservation.totalPrice.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoSection('Informations de la réservation', [
                  _buildInfoRow('ID', reservation.id),
                  _buildInfoRow('Date prévue',
                      dateFormat.format(reservation.departureTime)),
                  _buildInfoRow(
                      'Créée le', dateFormat.format(reservation.createdAt)),
                  if (reservation.completedAt != null)
                    _buildInfoRow('Terminée le',
                        dateFormat.format(reservation.completedAt!)),
                  if (reservation.cancelledAt != null)
                    _buildInfoRow('Annulée le',
                        dateFormat.format(reservation.cancelledAt!)),
                  if (reservation.parkingSpotNumber != null)
                    _buildInfoRow(
                        'Place de parking', reservation.parkingSpotNumber!),
                ]),
                const SizedBox(height: 20),
                _buildInfoSection('Détails financiers', [
                  _buildInfoRow('Prix total',
                      '${reservation.totalPrice.toStringAsFixed(2)} \$'),
                  _buildInfoRow('Commission plateforme',
                      '${reservation.platformFee.toStringAsFixed(2)} \$'),
                  _buildInfoRow('Paiement déneigeur',
                      '${reservation.workerPayout.toStringAsFixed(2)} \$'),
                  _buildInfoRow(
                      'Statut paiement', reservation.paymentStatus ?? 'N/A'),
                  if (reservation.isRefunded)
                    _buildInfoRow('Remboursé',
                        '${reservation.refundAmount?.toStringAsFixed(2) ?? 0} \$'),
                ]),
                if (reservation.client != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection('Client', [
                    _buildInfoRow('Nom', reservation.client!.fullName),
                    if (reservation.client!.email != null)
                      _buildInfoRow('Email', reservation.client!.email!),
                    if (reservation.client!.phoneNumber != null)
                      _buildInfoRow(
                          'Téléphone', reservation.client!.phoneNumber!),
                  ]),
                ],
                if (reservation.worker != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection('Déneigeur', [
                    _buildInfoRow('Nom', reservation.worker!.fullName),
                    if (reservation.worker!.phoneNumber != null)
                      _buildInfoRow(
                          'Téléphone', reservation.worker!.phoneNumber!),
                    if (reservation.worker!.rating != null)
                      _buildInfoRow('Note',
                          reservation.worker!.rating!.toStringAsFixed(1)),
                  ]),
                ],
                if (reservation.vehicle != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection('Véhicule', [
                    _buildInfoRow('Véhicule', reservation.vehicle!.displayName),
                    if (reservation.vehicle!.color != null)
                      _buildInfoRow('Couleur', reservation.vehicle!.color!),
                    if (reservation.vehicle!.licensePlate != null)
                      _buildInfoRow(
                          'Plaque', reservation.vehicle!.licensePlate!),
                  ]),
                ],
                if (reservation.serviceOptions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection('Services', [
                    _buildInfoRow(
                        'Options', reservation.serviceOptions.join(', ')),
                  ]),
                ],
                if (reservation.notes != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection('Notes', [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(reservation.notes!),
                    ),
                  ]),
                ],
                if (reservation.cancellationReason != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cancel, color: AppTheme.error),
                            const SizedBox(width: 8),
                            Text(
                              'Raison d\'annulation',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(reservation.cancellationReason!),
                      ],
                    ),
                  ),
                ],
                if (reservation.canRefund) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Procéder au remboursement'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showRefundDialog(pageContext, reservation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(BuildContext context, AdminReservation reservation) {
    final amountController = TextEditingController(
      text: reservation.totalPrice.toStringAsFixed(2),
    );
    final reasonController = TextEditingController();
    final adminBloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rembourser la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montant maximum: ${reservation.totalPrice.toStringAsFixed(2)} \$',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant à rembourser',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null ||
                  amount <= 0 ||
                  amount > reservation.totalPrice) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Montant invalide'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              adminBloc.add(RefundReservation(
                reservationId: reservation.id,
                amount: amount,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Rembourser'),
          ),
        ],
      ),
    );
  }
}
