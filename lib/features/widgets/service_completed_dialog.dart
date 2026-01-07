import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../reservation/domain/entities/reservation.dart';

class ServiceCompletedDialog extends StatefulWidget {
  final Reservation reservation;
  final Function(int rating, double? tip, String? comment) onSubmitRating;
  final VoidCallback? onViewDetails;

  const ServiceCompletedDialog({
    super.key,
    required this.reservation,
    required this.onSubmitRating,
    this.onViewDetails,
  });

  static Future<void> show(
    BuildContext context, {
    required Reservation reservation,
    required Function(int rating, double? tip, String? comment) onSubmitRating,
    VoidCallback? onViewDetails,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => ServiceCompletedDialog(
        reservation: reservation,
        onSubmitRating: onSubmitRating,
        onViewDetails: onViewDetails,
      ),
    );
  }

  @override
  State<ServiceCompletedDialog> createState() => _ServiceCompletedDialogState();
}

class _ServiceCompletedDialogState extends State<ServiceCompletedDialog>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  double? _selectedTip;
  final _commentController = TextEditingController();
  final _customTipController = TextEditingController();
  bool _showCustomTip = false;
  bool _showFullPhoto = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<double> _tipOptions = [0, 2, 5, 10];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    // Play success haptic
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _customTipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Header with animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.success.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Service terminé!',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'par ${widget.reservation.workerName ?? "votre déneigeur"}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Photo Result Section
                    if (widget.reservation.afterPhotoUrl != null) ...[
                      _buildPhotoSection(),
                      const SizedBox(height: 24),
                    ],

                    // Service Summary
                    _buildServiceSummary(),

                    const SizedBox(height: 24),

                    // Rating section
                    _buildRatingSection(),

                    const SizedBox(height: 24),

                    // Tip section
                    _buildTipSection(),

                    const SizedBox(height: 24),

                    // Comment section
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Commentaire (optionnel)',
                        hintStyle: TextStyle(color: AppTheme.textTertiary),
                        filled: true,
                        fillColor: AppTheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total summary
                    if (_selectedTip != null && _selectedTip! > 0)
                      _buildTotalSummary(),

                    const SizedBox(height: 16),

                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Photo du résultat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showFullPhoto = !_showFullPhoto;
                });
              },
              icon: Icon(
                _showFullPhoto ? Icons.fullscreen_exit : Icons.fullscreen,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              label: Text(
                _showFullPhoto ? 'Réduire' : 'Agrandir',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showPhotoFullscreen(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showFullPhoto ? 300 : 180,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.reservation.afterPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceContainer,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceContainer,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: AppTheme.textTertiary, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Photo non disponible',
                        style: TextStyle(color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Appuyez pour voir en plein écran',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoFullscreen(BuildContext context) {
    if (widget.reservation.afterPhotoUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            iconTheme: IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              'Photo du résultat',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.reservation.afterPhotoUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: AppTheme.textPrimary),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.error,
                  color: AppTheme.textPrimary,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.reservation.vehicle.make} ${widget.reservation.vehicle.model}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.reservation.parkingSpot.displayName,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          Divider(height: 24, color: AppTheme.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prix du service',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '${widget.reservation.totalPrice.toStringAsFixed(2)} \$',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        Text(
          'Comment était le service?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected = starNumber <= _rating;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _rating = starNumber;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: isSelected ? AppTheme.warning : AppTheme.textTertiary,
                  size: 44,
                ),
              ),
            );
          }),
        ),
        if (_rating > 0)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getRatingText(_rating),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTipSection() {
    return Column(
      children: [
        Text(
          'Ajouter un pourboire?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '100% va au déneigeur',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._tipOptions.map((tip) => _buildTipOption(tip)),
            _buildCustomTipButton(),
          ],
        ),
        if (_showCustomTip) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _customTipController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Montant',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                suffixText: '\$',
                suffixStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null) {
                  setState(() {
                    _selectedTip = amount;
                  });
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTipOption(double amount) {
    final isSelected = _selectedTip == amount && !_showCustomTip;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTip = amount;
          _showCustomTip = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimary : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.textPrimary : AppTheme.border,
            width: 2,
          ),
        ),
        child: Text(
          amount == 0 ? 'Non' : '${amount.toInt()}\$',
          style: TextStyle(
            color: isSelected ? AppTheme.background : AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _showCustomTip = true;
          _selectedTip = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _showCustomTip ? AppTheme.textPrimary : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showCustomTip ? AppTheme.textPrimary : AppTheme.border,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.edit,
          color: _showCustomTip ? AppTheme.background : AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pourboire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            '+ ${_selectedTip!.toStringAsFixed(2)} \$',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _rating > 0
                ? () {
                    HapticFeedback.mediumImpact();
                    widget.onSubmitRating(
                      _rating,
                      _selectedTip,
                      _commentController.text.isNotEmpty
                          ? _commentController.text
                          : null,
                    );
                    Navigator.pop(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppTheme.surfaceContainer,
              disabledForegroundColor: AppTheme.textTertiary,
            ),
            child: Text(
              _selectedTip != null && _selectedTip! > 0
                  ? 'Envoyer avec ${_selectedTip!.toStringAsFixed(0)}\$ de pourboire'
                  : 'Envoyer l\'évaluation',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // View details button
        if (widget.onViewDetails != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onViewDetails!();
            },
            icon: Icon(Icons.visibility, color: AppTheme.textSecondary),
            label: Text(
              'Voir les détails',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),

        // Skip button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Plus tard',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Correct';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
