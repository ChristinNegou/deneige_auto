import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admin_reservationsManagement),
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
    final l10n = AppLocalizations.of(context)!;
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
            _buildStatusChip(context, l10n.admin_all, null),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, l10n.admin_pending, 'pending', AppTheme.warning),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, l10n.admin_assigned, 'assigned', AppTheme.info),
            const SizedBox(width: 8),
            _buildStatusChip(context, l10n.admin_inProgress, 'inProgress',
                AppTheme.primary2),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, l10n.admin_completed, 'completed', AppTheme.success),
            const SizedBox(width: 8),
            _buildStatusChip(
                context, l10n.admin_cancelled, 'cancelled', AppTheme.error),
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
    final l10n = AppLocalizations.of(context)!;

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
            Text(state.errorMessage ?? l10n.common_errorOccurred),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AdminBloc>().add(LoadReservations()),
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      );
    }

    if (state.reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today,
                size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(l10n.admin_noReservations),
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
    final l10n = AppLocalizations.of(context)!;
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
                        label: Text(l10n.admin_refund),
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
                      label: Text(l10n.admin_viewDetails),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.admin_pageOf(
                state.reservationsPage, state.reservationsTotalPages),
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
    final l10n = AppLocalizations.of(context)!;
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
                _buildInfoSection(l10n.admin_reservationInfo, [
                  _buildInfoRow(l10n.admin_id, reservation.id),
                  _buildInfoRow(l10n.admin_plannedDate,
                      dateFormat.format(reservation.departureTime)),
                  _buildInfoRow(l10n.admin_createdAt,
                      dateFormat.format(reservation.createdAt)),
                  if (reservation.completedAt != null)
                    _buildInfoRow(l10n.admin_completedAt,
                        dateFormat.format(reservation.completedAt!)),
                  if (reservation.cancelledAt != null)
                    _buildInfoRow(l10n.admin_cancelledAt,
                        dateFormat.format(reservation.cancelledAt!)),
                  if (reservation.parkingSpotNumber != null)
                    _buildInfoRow(
                        l10n.admin_parkingSpot, reservation.parkingSpotNumber!),
                ]),
                const SizedBox(height: 20),
                _buildInfoSection(l10n.admin_financialDetails, [
                  _buildInfoRow(l10n.admin_totalPrice,
                      '${reservation.totalPrice.toStringAsFixed(2)} \$'),
                  _buildInfoRow(l10n.admin_platformFee,
                      '${reservation.platformFee.toStringAsFixed(2)} \$'),
                  _buildInfoRow(l10n.admin_workerPayment,
                      '${reservation.workerPayout.toStringAsFixed(2)} \$'),
                  _buildInfoRow(l10n.admin_paymentStatus,
                      reservation.paymentStatus ?? 'N/A'),
                  if (reservation.isRefunded)
                    _buildInfoRow(l10n.admin_refunded,
                        '${reservation.refundAmount?.toStringAsFixed(2) ?? 0} \$'),
                ]),
                if (reservation.client != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection(l10n.admin_client, [
                    _buildInfoRow(
                        l10n.common_name, reservation.client!.fullName),
                    if (reservation.client!.email != null)
                      _buildInfoRow(
                          l10n.common_email, reservation.client!.email!),
                    if (reservation.client!.phoneNumber != null)
                      _buildInfoRow(
                          l10n.common_phone, reservation.client!.phoneNumber!),
                  ]),
                ],
                if (reservation.worker != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection(l10n.admin_workerLabel, [
                    _buildInfoRow(
                        l10n.common_name, reservation.worker!.fullName),
                    if (reservation.worker!.phoneNumber != null)
                      _buildInfoRow(
                          l10n.common_phone, reservation.worker!.phoneNumber!),
                    if (reservation.worker!.rating != null)
                      _buildInfoRow(l10n.admin_note,
                          reservation.worker!.rating!.toStringAsFixed(1)),
                  ]),
                ],
                if (reservation.vehicle != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection(l10n.reservation_vehicle, [
                    _buildInfoRow(l10n.reservation_vehicle,
                        reservation.vehicle!.displayName),
                    if (reservation.vehicle!.color != null)
                      _buildInfoRow(
                          l10n.admin_color, reservation.vehicle!.color!),
                    if (reservation.vehicle!.licensePlate != null)
                      _buildInfoRow(l10n.admin_plateNumber,
                          reservation.vehicle!.licensePlate!),
                  ]),
                ],
                if (reservation.serviceOptions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection(l10n.admin_services, [
                    _buildInfoRow(l10n.admin_services,
                        reservation.serviceOptions.join(', ')),
                  ]),
                ],
                if (reservation.notes != null) ...[
                  const SizedBox(height: 20),
                  _buildInfoSection(l10n.common_notes, [
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
                              l10n.admin_cancellationReason,
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
                      label: Text(l10n.admin_proceedRefund),
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
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController(
      text: reservation.totalPrice.toStringAsFixed(2),
    );
    final reasonController = TextEditingController();
    final adminBloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.admin_refundTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.admin_maxAmount} ${reservation.totalPrice.toStringAsFixed(2)} \$',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.admin_refundAmount,
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.admin_reasonOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null ||
                  amount <= 0 ||
                  amount > reservation.totalPrice) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(l10n.admin_invalidAmount),
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
            child: Text(l10n.admin_refund),
          ),
        ],
      ),
    );
  }
}
