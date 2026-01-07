import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dialog pour noter un déneigeur après un job complété
class RatingDialog extends StatefulWidget {
  final String workerName;
  final String? workerPhotoUrl;
  final Function(int rating, String? review) onSubmit;
  final VoidCallback? onSkip;

  const RatingDialog({
    super.key,
    required this.workerName,
    this.workerPhotoUrl,
    required this.onSubmit,
    this.onSkip,
  });

  /// Affiche le dialog de notation
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String workerName,
    String? workerPhotoUrl,
    bool canSkip = true,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        workerName: workerName,
        workerPhotoUrl: workerPhotoUrl,
        onSubmit: (rating, review) {
          Navigator.of(context).pop({
            'rating': rating,
            'review': review,
            'skipped': false,
          });
        },
        onSkip: canSkip
            ? () {
                Navigator.of(context).pop({
                  'skipped': true,
                });
              }
            : null,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getRatingText() {
    switch (_selectedRating) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Correct';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Excellent !';
      default:
        return 'Touchez pour noter';
    }
  }

  Color _getRatingColor() {
    switch (_selectedRating) {
      case 1:
        return AppTheme.error;
      case 2:
        return AppTheme.warning;
      case 3:
        return AppTheme.warning;
      case 4:
        return AppTheme.success;
      case 5:
        return AppTheme.success;
      default:
        return AppTheme.textTertiary;
    }
  }

  void _handleSubmit() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une note'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    widget.onSubmit(
      _selectedRating,
      _reviewController.text.trim().isEmpty
          ? null
          : _reviewController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec avatar
              _buildHeader(),
              const SizedBox(height: 20),

              // Texte d'invitation
              Text(
                'Comment s\'est passé le déneigement ?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre avis aide à améliorer le service',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Étoiles de notation
              _buildStarsRow(),
              const SizedBox(height: 8),

              // Texte de rating
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getRatingText(),
                  key: ValueKey(_selectedRating),
                  style: TextStyle(
                    color: _getRatingColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Champ de commentaire (optionnel)
              _buildReviewField(),
              const SizedBox(height: 24),

              // Boutons
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Avatar du déneigeur
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.workerPhotoUrl != null
              ? ClipOval(
                  child: Image.network(
                    widget.workerPhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      color: AppTheme.background,
                      size: 40,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: AppTheme.background,
                  size: 40,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.workerName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Déneigeur',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStarsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _selectedRating;

        return GestureDetector(
          onTap: () => setState(() => _selectedRating = starIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 48,
              color: isSelected ? AppTheme.warning : AppTheme.border,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewField() {
    return TextField(
      controller: _reviewController,
      maxLines: 3,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'Ajouter un commentaire (optionnel)',
        hintStyle: TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        counterStyle: TextStyle(color: AppTheme.textTertiary),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Bouton soumettre
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.background,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Envoyer mon avis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),

        // Bouton passer
        if (widget.onSkip != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Peut-être plus tard',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget pour afficher les étoiles de notation (lecture seule)
class RatingStars extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final bool showCount;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 16,
    this.showCount = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          IconData icon;

          if (rating >= starIndex) {
            icon = Icons.star_rounded;
          } else if (rating >= starIndex - 0.5) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }

          return Icon(
            icon,
            size: size,
            color: color ?? AppTheme.warning,
          );
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '-',
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          if (totalRatings > 0) ...[
            Text(
              ' ($totalRatings)',
              style: TextStyle(
                fontSize: size * 0.7,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
