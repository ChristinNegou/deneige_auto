import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/admin_support_request.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadSupportRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminBloc>().add(
                  LoadSupportRequests(status: _selectedStatus),
                ),
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
              _buildFilters(context),
              Expanded(child: _buildRequestsList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
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
            _buildFilterChip(context, 'Tous', null),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'En attente', 'pending'),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'En cours', 'in_progress'),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Résolu', 'resolved'),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Fermé', 'closed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = selected ? status : null);
        context.read<AdminBloc>().add(
              LoadSupportRequests(status: selected ? status : null),
            );
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
    );
  }

  Widget _buildRequestsList(BuildContext context, AdminState state) {
    if (state.supportStatus == AdminStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.supportStatus == AdminStatus.error) {
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
                  context.read<AdminBloc>().add(LoadSupportRequests()),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.supportRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: AppTheme.textTertiary),
            SizedBox(height: 16),
            Text('Aucune demande de support'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(
              LoadSupportRequests(status: _selectedStatus),
            );
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.supportRequests.length,
              itemBuilder: (context, index) {
                final request = state.supportRequests[index];
                return _buildRequestCard(context, request);
              },
            ),
          ),
          if (state.supportTotalPages > 1) _buildPagination(context, state),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, AdminSupportRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRequestDetails(context, request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getSubjectColor(request.subject)
                        .withValues(alpha: 0.2),
                    child: Icon(
                      _getSubjectIcon(request.subject),
                      size: 20,
                      color: _getSubjectColor(request.subject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          request.userEmail,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getSubjectColor(request.subject).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.subject.label,
                  style: TextStyle(
                    color: _getSubjectColor(request.subject),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(request.createdAt),
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SupportStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(SupportStatus status) {
    switch (status) {
      case SupportStatus.pending:
        return AppTheme.warning;
      case SupportStatus.inProgress:
        return AppTheme.info;
      case SupportStatus.resolved:
        return AppTheme.success;
      case SupportStatus.closed:
        return AppTheme.textTertiary;
    }
  }

  Color _getSubjectColor(SupportSubject subject) {
    switch (subject) {
      case SupportSubject.bug:
        return AppTheme.error;
      case SupportSubject.question:
        return AppTheme.info;
      case SupportSubject.suggestion:
        return AppTheme.success;
      case SupportSubject.other:
        return AppTheme.textSecondary;
    }
  }

  IconData _getSubjectIcon(SupportSubject subject) {
    switch (subject) {
      case SupportSubject.bug:
        return Icons.bug_report;
      case SupportSubject.question:
        return Icons.help_outline;
      case SupportSubject.suggestion:
        return Icons.lightbulb_outline;
      case SupportSubject.other:
        return Icons.more_horiz;
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
            onPressed: state.supportPage > 1
                ? () {
                    context.read<AdminBloc>().add(LoadSupportRequests(
                          page: state.supportPage - 1,
                          status: _selectedStatus,
                        ));
                  }
                : null,
          ),
          Text(
            'Page ${state.supportPage} / ${state.supportTotalPages}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.supportPage < state.supportTotalPages
                ? () {
                    context.read<AdminBloc>().add(LoadSupportRequests(
                          page: state.supportPage + 1,
                          status: _selectedStatus,
                        ));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context, AdminSupportRequest request) {
    final adminBloc = context.read<AdminBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _getSubjectColor(request.subject)
                          .withValues(alpha: 0.2),
                      child: Icon(
                        _getSubjectIcon(request.subject),
                        size: 28,
                        color: _getSubjectColor(request.subject),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.subject.label,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(request.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(Icons.person, 'Utilisateur', request.userName),
                _buildDetailRow(Icons.email, 'Email', request.userEmail),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  _formatDate(request.createdAt),
                ),
                const Divider(height: 32),
                const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    request.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (request.adminNotes != null &&
                    request.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Notes admin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      request.adminNotes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showUpdateStatusDialog(context, request, adminBloc);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Statut'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showAddNotesDialog(context, request, adminBloc);
                        },
                        icon: const Icon(Icons.note_add),
                        label: const Text('Note'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showRespondDialog(context, request, adminBloc);
                        },
                        icon: const Icon(Icons.reply),
                        label: const Text('Répondre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showDeleteConfirmDialog(context, request, adminBloc);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(
      BuildContext context, AdminSupportRequest request, AdminBloc adminBloc) {
    SupportStatus selectedStatus = request.status;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le statut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: SupportStatus.values.map((status) {
              return RadioListTile<SupportStatus>(
                title: Text(status.label),
                value: status,
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() => selectedStatus = value!);
                },
                activeColor: AppTheme.primary,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                adminBloc.add(UpdateSupportRequest(
                  requestId: request.id,
                  status: selectedStatus.value,
                ));
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotesDialog(
      BuildContext context, AdminSupportRequest request, AdminBloc adminBloc) {
    final notesController = TextEditingController(text: request.adminNotes);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notes admin'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Ajouter des notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              adminBloc.add(UpdateSupportRequest(
                requestId: request.id,
                adminNotes: notesController.text,
              ));
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showRespondDialog(
      BuildContext context, AdminSupportRequest request, AdminBloc adminBloc) {
    final messageController = TextEditingController();
    bool sendEmail = true;
    bool sendNotification = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.reply, color: AppTheme.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Répondre à la demande')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        request.userEmail,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Votre réponse',
                    hintText: 'Écrivez votre réponse ici...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: sendEmail,
                  onChanged: (value) => setState(() => sendEmail = value!),
                  title: const Text('Envoyer par email'),
                  subtitle: Text(
                    request.userEmail,
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                CheckboxListTile(
                  value: sendNotification,
                  onChanged: (value) =>
                      setState(() => sendNotification = value!),
                  title: const Text('Envoyer une notification'),
                  subtitle: Text(
                    'Notification push dans l\'app',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Envoyer'),
              onPressed: () {
                if (messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: const Text('Veuillez écrire une réponse'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
                if (!sendEmail && !sendNotification) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Sélectionnez au moins un mode d\'envoi'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                adminBloc.add(RespondToSupportRequest(
                  requestId: request.id,
                  responseMessage: messageController.text.trim(),
                  sendEmail: sendEmail,
                  sendNotification: sendNotification,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, AdminSupportRequest request, AdminBloc adminBloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Supprimer la demande'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir supprimer cette demande de support ?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.subject.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.userName,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cette action est irréversible.',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              adminBloc.add(DeleteSupportRequest(request.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
