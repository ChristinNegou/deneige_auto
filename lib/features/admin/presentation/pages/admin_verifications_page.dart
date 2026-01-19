import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/data/datasources/admin_remote_datasource.dart';
import '../../../../core/di/injection_container.dart';

class AdminVerificationsPage extends StatefulWidget {
  const AdminVerificationsPage({super.key});

  @override
  State<AdminVerificationsPage> createState() => _AdminVerificationsPageState();
}

class _AdminVerificationsPageState extends State<AdminVerificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<dynamic> _verifications = [];
  Map<String, dynamic> _stats = {};
  String _currentStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final statuses = ['pending', 'approved', 'rejected', 'all'];
    setState(() {
      _currentStatus = statuses[_tabController.index];
    });
    _loadVerifications();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadVerifications(),
      _loadStats(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final datasource = sl<AdminRemoteDataSource>();
      final response = await datasource.getVerificationStats();
      if (mounted) {
        setState(() {
          _stats = response['data'] ?? {};
        });
      }
    } catch (e) {
      // Silent fail for stats
    }
  }

  Future<void> _loadVerifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final datasource = sl<AdminRemoteDataSource>();
      final response = await datasource.getVerifications(
        status: _currentStatus == 'all' ? null : _currentStatus,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      if (mounted) {
        setState(() {
          _verifications = response['data']?['verifications'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Vérifications d\'identité'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('En attente'),
                  if (_stats['pending'] != null && _stats['pending'] > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_stats['pending']}',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approuvées'),
            const Tab(text: 'Rejetées'),
            const Tab(text: 'Toutes'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _buildVerificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('En attente', '${_stats['pending'] ?? 0}',
              Icons.hourglass_empty, AppTheme.warning),
          _buildStatItem('Approuvées', '${_stats['approved'] ?? 0}',
              Icons.check_circle, AppTheme.success),
          _buildStatItem('Rejetées', '${_stats['rejected'] ?? 0}', Icons.cancel,
              AppTheme.error),
          _buildStatItem(
              'Total', '${_stats['total'] ?? 0}', Icons.people, Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.background,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.background.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par nom...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadVerifications();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onSubmitted: (_) => _loadVerifications(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(_error ?? 'Une erreur est survenue'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVerifications,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsList() {
    if (_verifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              _currentStatus == 'pending'
                  ? 'Aucune vérification en attente'
                  : 'Aucune vérification trouvée',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _verifications.length,
        itemBuilder: (context, index) {
          final verification = _verifications[index];
          return _buildVerificationCard(verification);
        },
      ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> item) {
    // API response structure: {userId, name, email, verification: {status, aiAnalysis, ...}}
    final verificationData = item['verification'] ?? {};
    final status = verificationData['status'] ?? 'pending';
    final aiAnalysis = verificationData['aiAnalysis'];
    final submittedAt = verificationData['submittedAt'] != null
        ? DateTime.tryParse(verificationData['submittedAt'])
        : null;
    final documents = verificationData['documents'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showVerificationDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Selfie preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: documents['selfie']?['url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              documents['selfie']['url'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppTheme.primary,
                                size: 32,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['email'] ?? '',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (submittedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Soumis le ${_formatDate(submittedAt)}',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              if (aiAnalysis != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreIndicator(
                      'Visage',
                      aiAnalysis['faceMatchScore']?.toDouble() ?? 0,
                      Icons.face,
                    ),
                    _buildScoreIndicator(
                      'Document',
                      aiAnalysis['documentAuthenticityScore']?.toDouble() ?? 0,
                      Icons.badge,
                    ),
                    _buildScoreIndicator(
                      'Liveness',
                      aiAnalysis['livenessScore']?.toDouble() ?? 0,
                      Icons.visibility,
                    ),
                    _buildScoreIndicator(
                      'Global',
                      aiAnalysis['overallScore']?.toDouble() ?? 0,
                      Icons.analytics,
                      isMain: true,
                    ),
                  ],
                ),
              ] else if (status == 'pending') ...[
                // No AI analysis yet - show reanalyze hint
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Analyse IA non effectuée - Cliquez pour relancer',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'approved':
        color = AppTheme.success;
        text = 'Approuvé';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppTheme.error;
        text = 'Rejeté';
        icon = Icons.cancel;
        break;
      case 'expired':
        color = AppTheme.warning;
        text = 'Expiré';
        icon = Icons.timer_off;
        break;
      default:
        color = AppTheme.warning;
        text = 'En attente';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, double score, IconData icon,
      {bool isMain = false}) {
    Color color;
    if (score >= 80) {
      color = AppTheme.success;
    } else if (score >= 60) {
      color = AppTheme.warning;
    } else {
      color = AppTheme.error;
    }

    return Column(
      children: [
        Container(
          width: isMain ? 48 : 40,
          height: isMain ? 48 : 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isMain ? 24 : 8),
            border: isMain
                ? Border.all(color: color, width: 2)
                : Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              '${score.toInt()}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isMain ? 16 : 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showVerificationDetails(Map<String, dynamic> item) {
    // API response structure: {userId, name, email, verification: {status, documents, aiAnalysis, decision}}
    final verificationData = item['verification'] ?? {};
    final documents = verificationData['documents'] ?? {};
    final aiAnalysis = verificationData['aiAnalysis'];
    final decision = verificationData['decision'];
    final status = verificationData['status'] ?? 'pending';
    final userId = item['userId'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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

                // User info
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: documents['selfie']?['url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                documents['selfie']['url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: AppTheme.primary,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(Icons.person,
                              color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            item['email'] ?? '',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 24),

                // Documents gallery
                const Text(
                  'Documents soumis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (documents['idFront']?['url'] != null)
                        _buildDocumentImage(
                            'Pièce ID (recto)', documents['idFront']['url']),
                      if (documents['idBack']?['url'] != null)
                        _buildDocumentImage(
                            'Pièce ID (verso)', documents['idBack']['url']),
                      if (documents['selfie']?['url'] != null)
                        _buildDocumentImage(
                            'Selfie', documents['selfie']['url']),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI Analysis
                if (aiAnalysis != null) ...[
                  const Text(
                    'Analyse IA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildAnalysisCard(aiAnalysis),
                  const SizedBox(height: 24),
                ] else if (status == 'pending' &&
                    documents['idFront']?['url'] != null) ...[
                  // No AI analysis - show reanalyze button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppTheme.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'L\'analyse IA n\'a pas été effectuée pour cette vérification.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _reanalyzeVerification(userId, sheetContext),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Relancer l\'analyse IA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Previous decision
                if (decision != null) ...[
                  const Text(
                    'Décision précédente',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              decision['result'] == 'approved'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: decision['result'] == 'approved'
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              decision['result'] == 'approved'
                                  ? 'Approuvé'
                                  : 'Rejeté',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              decision['decidedBy'] == 'auto'
                                  ? 'Auto'
                                  : 'Admin',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (decision['reason'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            decision['reason'],
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                if (status == 'pending') ...[
                  const Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleDecision(
                            userId,
                            'approved',
                            sheetContext,
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approuver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(
                            userId,
                            sheetContext,
                          ),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Rejeter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildDocumentImage(String label, String url) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showFullImage(url),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image,
                          color: AppTheme.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final issues = analysis['issues'] as List<dynamic>? ?? [];
    final extractedData = analysis['extractedData'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailedScore('Correspondance visage',
                  analysis['faceMatchScore']?.toDouble() ?? 0, Icons.face),
              _buildDetailedScore(
                  'Authenticité document',
                  analysis['documentAuthenticityScore']?.toDouble() ?? 0,
                  Icons.badge),
              _buildDetailedScore('Liveness',
                  analysis['livenessScore']?.toDouble() ?? 0, Icons.visibility),
            ],
          ),
          const SizedBox(height: 16),

          // Overall score
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getScoreColor(analysis['overallScore']?.toDouble() ?? 0)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics,
                    color: _getScoreColor(
                        analysis['overallScore']?.toDouble() ?? 0)),
                const SizedBox(width: 8),
                Text(
                  'Score global: ${analysis['overallScore']?.toInt() ?? 0}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _getScoreColor(
                        analysis['overallScore']?.toDouble() ?? 0),
                  ),
                ),
              ],
            ),
          ),

          // Extracted data
          if (extractedData.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Informations extraites',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (extractedData['documentType'] != null)
              _buildDataRow('Type de document', extractedData['documentType']),
            if (extractedData['fullName'] != null)
              _buildDataRow('Nom complet', extractedData['fullName']),
            if (extractedData['expiryDate'] != null)
              _buildDataRow('Date d\'expiration', extractedData['expiryDate']),
          ],

          // Issues
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warning, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Problèmes détectés',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      Expanded(
                        child: Text(
                          issue.toString(),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedScore(String label, double score, IconData icon) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                backgroundColor: AppTheme.border,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
              ),
            ),
            Icon(icon, color: _getScoreColor(score), size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${score.toInt()}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDecision(
      String userId, String decision, BuildContext sheetContext) async {
    try {
      final datasource = sl<AdminRemoteDataSource>();
      await datasource.submitVerificationDecision(
        userId,
        decision: decision,
      );

      if (mounted) {
        Navigator.pop(sheetContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decision == 'approved'
                ? 'Vérification approuvée'
                : 'Vérification rejetée'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showRejectDialog(String userId, BuildContext sheetContext) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter la vérification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison',
                border: OutlineInputBorder(),
                hintText: 'Ex: Document illisible, photo floue...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final datasource = sl<AdminRemoteDataSource>();
                await datasource.submitVerificationDecision(
                  userId,
                  decision: 'rejected',
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Vérification non conforme',
                );

                if (mounted) {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Vérification rejetée'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<void> _reanalyzeVerification(
      String userId, BuildContext sheetContext) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Expanded(
                child: Text(
                    'Analyse IA en cours...\nCela peut prendre jusqu\'à 30 secondes.')),
          ],
        ),
      ),
    );

    try {
      final datasource = sl<AdminRemoteDataSource>();
      final result = await datasource.reanalyzeVerification(userId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(sheetContext); // Close bottom sheet

        final status = result['data']?['status'] ?? 'pending';
        final score = result['data']?['overallScore'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Vérification auto-approuvée (score: $score%)'
                  : status == 'rejected'
                      ? 'Vérification auto-rejetée'
                      : 'Analyse terminée - révision manuelle requise (score: $score%)',
            ),
            backgroundColor: status == 'approved'
                ? AppTheme.success
                : status == 'rejected'
                    ? AppTheme.error
                    : AppTheme.warning,
            duration: const Duration(seconds: 4),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
