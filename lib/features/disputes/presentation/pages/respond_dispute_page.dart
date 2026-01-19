import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Écran pour répondre à un litige (côté déneigeur)
class RespondDisputePage extends StatefulWidget {
  final String disputeId;
  final String disputeType;
  final String disputeDescription;
  final DateTime? responseDeadline;

  const RespondDisputePage({
    super.key,
    required this.disputeId,
    required this.disputeType,
    required this.disputeDescription,
    this.responseDeadline,
  });

  @override
  State<RespondDisputePage> createState() => _RespondDisputePageState();
}

class _RespondDisputePageState extends State<RespondDisputePage> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  late DisputeService _disputeService;

  bool _isLoading = false;
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible de charger l\'image'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajouter une preuve',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primary),
                ),
                title: Text(
                  'Prendre une photo',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: AppTheme.primary),
                ),
                title: Text(
                  'Choisir depuis la galerie',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRemainingTime() {
    if (widget.responseDeadline == null) return 'Non spécifié';

    final now = DateTime.now();
    final diff = widget.responseDeadline!.difference(now);

    if (diff.isNegative) {
      return 'Délai dépassé';
    }

    if (diff.inDays > 0) {
      return '${diff.inDays}j ${diff.inHours % 24}h restantes';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}min restantes';
    } else {
      return '${diff.inMinutes}min restantes';
    }
  }

  bool _isDeadlinePassed() {
    if (widget.responseDeadline == null) return false;
    return DateTime.now().isAfter(widget.responseDeadline!);
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isDeadlinePassed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le délai de réponse est dépassé'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Upload photos to cloud storage and get URLs
      // For now, we'll send without photos if the service expects URLs
      List<String>? photoUrls;
      // In a real implementation, upload photos here and collect URLs

      await _disputeService.respondToDispute(
        disputeId: widget.disputeId,
        text: _responseController.text.trim(),
        photos: photoUrls,
      );

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Exception:')
                ? e.toString().replaceFirst('Exception: ', '')
                : 'Erreur lors de l\'envoi de la réponse',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppTheme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Réponse envoyée',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre réponse a été enregistrée. L\'administrateur va examiner le litige et prendra une décision.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vous serez notifié de la décision finale.',
                      style: TextStyle(
                        color: AppTheme.info,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deadlinePassed = _isDeadlinePassed();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Répondre au litige',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Deadline Warning
                if (widget.responseDeadline != null)
                  _buildDeadlineCard(deadlinePassed),
                const SizedBox(height: 20),

                // Complaint Summary
                _buildComplaintCard(),
                const SizedBox(height: 24),

                // Response Section
                _buildSectionTitle('Votre réponse'),
                const SizedBox(height: 8),
                Text(
                  'Expliquez votre version des faits. Soyez précis et factuel.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                _buildResponseField(),
                const SizedBox(height: 24),

                // Photos Section
                _buildSectionTitle('Photos/Preuves'),
                const SizedBox(height: 12),
                _buildPhotoSection(),
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(deadlinePassed),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(bool deadlinePassed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deadlinePassed ? AppTheme.errorLight : AppTheme.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deadlinePassed ? AppTheme.error : AppTheme.warning,
        ),
      ),
      child: Row(
        children: [
          Icon(
            deadlinePassed ? Icons.error : Icons.schedule,
            color: deadlinePassed ? AppTheme.error : AppTheme.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadlinePassed
                      ? 'Délai de réponse dépassé'
                      : 'Délai de réponse',
                  style: TextStyle(
                    color: deadlinePassed ? AppTheme.error : AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getRemainingTime(),
                  style: TextStyle(
                    color: deadlinePassed ? AppTheme.error : AppTheme.warning,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.report_problem, color: AppTheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Plainte reçue',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.disputeType,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.disputeDescription,
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildResponseField() {
    return TextFormField(
      controller: _responseController,
      maxLines: 6,
      maxLength: 2000,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText:
            'Écrivez votre réponse ici...\n\n• Décrivez ce qui s\'est passé\n• Mentionnez les preuves que vous avez\n• Restez professionnel',
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error),
        ),
        counterStyle: TextStyle(color: AppTheme.textTertiary),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez écrire votre réponse';
        }
        if (value.trim().length < 50) {
          return 'Votre réponse est trop courte (minimum 50 caractères)';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajoutez des photos pour appuyer votre réponse (photos du travail effectué, captures d\'écran de conversation, etc.)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),

        // Photo grid
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _photos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _photos.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (_photos.isNotEmpty) const SizedBox(height: 12),

        // Add photo button
        if (_photos.length < 10)
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _photos.isEmpty
                        ? 'Ajouter des preuves'
                        : 'Ajouter une autre photo',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),
        Text(
          'Maximum 10 photos',
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool deadlinePassed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isLoading || deadlinePassed) ? null : _submitResponse,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.background),
                ),
              )
            : Text(
                deadlinePassed ? 'Délai dépassé' : 'Envoyer ma réponse',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
