import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Écran pour ajouter des preuves supplémentaires à un litige
class AddEvidencePage extends StatefulWidget {
  final String disputeId;
  final String disputeStatus;

  const AddEvidencePage({
    super.key,
    required this.disputeId,
    required this.disputeStatus,
  });

  @override
  State<AddEvidencePage> createState() => _AddEvidencePageState();
}

class _AddEvidencePageState extends State<AddEvidencePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
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
    _descriptionController.dispose();
    super.dispose();
  }

  bool _canAddEvidence() {
    // Les preuves peuvent être ajoutées tant que le litige n'est pas résolu/fermé
    return !['resolved', 'closed'].contains(widget.disputeStatus);
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

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            if (_photos.length < 10) {
              _photos.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible de charger les images'),
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
                'Ajouter des preuves',
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
                subtitle: Text(
                  'Sélection multiple possible',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitEvidence() async {
    if (_photos.isEmpty && _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajoutez au moins une photo ou une description'),
          backgroundColor: AppTheme.warning,
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

      await _disputeService.addEvidence(
        disputeId: widget.disputeId,
        photos: photoUrls,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
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
                : 'Erreur lors de l\'ajout des preuves',
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
                'Preuves ajoutées',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Vos preuves ont été ajoutées au dossier du litige. L\'équipe de support les examinera dans les plus brefs délais.',
          style: TextStyle(color: AppTheme.textSecondary),
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
    final canAdd = _canAddEvidence();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Ajouter des preuves',
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
                // Status Warning
                if (!canAdd) _buildStatusWarning(),
                if (!canAdd) const SizedBox(height: 20),

                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 24),

                // Photos Section
                _buildSectionTitle('Photos'),
                const SizedBox(height: 12),
                _buildPhotoSection(canAdd),
                const SizedBox(height: 24),

                // Description Section
                _buildSectionTitle('Description (optionnel)'),
                const SizedBox(height: 12),
                _buildDescriptionField(canAdd),
                const SizedBox(height: 32),

                // Submit Button
                if (canAdd) _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppTheme.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ce litige est déjà résolu. Vous ne pouvez plus ajouter de preuves.',
              style: TextStyle(
                color: AppTheme.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.info, size: 20),
              const SizedBox(width: 10),
              Text(
                'Conseils pour vos preuves',
                style: TextStyle(
                  color: AppTheme.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Photos claires et bien éclairées'),
          _buildTip('Captures d\'écran de communications'),
          _buildTip('Photos horodatées si possible'),
          _buildTip('Tout document pertinent'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppTheme.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.info,
                fontSize: 13,
              ),
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

  Widget _buildPhotoSection(bool enabled) {
    return Column(
      children: [
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
                  if (enabled)
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
        if (_photos.length < 10 && enabled)
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, color: AppTheme.primary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _photos.isEmpty
                        ? 'Ajouter des photos'
                        : 'Ajouter plus de photos',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_photos.length}/10 photos',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionField(bool enabled) {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      maxLength: 500,
      enabled: enabled,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Décrivez les preuves ajoutées...',
        hintStyle: TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: enabled
            ? AppTheme.surfaceContainer
            : AppTheme.surfaceContainer.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        counterStyle: TextStyle(color: AppTheme.textTertiary),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasContent =
        _photos.isNotEmpty || _descriptionController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isLoading || !hasContent) ? null : _submitEvidence,
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
            : const Text(
                'Soumettre les preuves',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
