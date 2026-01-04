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
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleSubmit() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: Colors.orange,
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
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: Colors.white,
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
              color: isSelected ? Colors.amber : Colors.grey.shade300,
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
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        counterStyle: TextStyle(color: Colors.grey.shade500),
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
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
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
                color: Colors.grey.shade600,
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
            color: color ?? Colors.amber,
          );
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '-',
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          if (totalRatings > 0) ...[
            Text(
              ' ($totalRatings)',
              style: TextStyle(
                fontSize: size * 0.7,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
