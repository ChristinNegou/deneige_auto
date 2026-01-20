import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/verification_bloc.dart';
import 'selfie_capture_page.dart';

class DocumentCapturePage extends StatefulWidget {
  const DocumentCapturePage({super.key});

  @override
  State<DocumentCapturePage> createState() => _DocumentCapturePageState();
}

class _DocumentCapturePageState extends State<DocumentCapturePage> {
  final ImagePicker _picker = ImagePicker();
  File? _idFront;
  File? _idBack;
  bool _isCapturingFront = true;

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          if (_isCapturingFront) {
            _idFront = File(image.path);
          } else {
            _idBack = File(image.path);
          }
        });
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isCapturingFront
                    ? 'Photographier le recto'
                    : 'Photographier le verso',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primary),
                ),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Utiliser la caméra'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: AppTheme.secondary),
                ),
                title: const Text('Choisir une photo'),
                subtitle: const Text('Depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToSelfie() {
    if (_idFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez photographier le recto de votre pièce d\'identité'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final bloc = context.read<VerificationBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: SelfieCapturePageArgs(
            idFront: _idFront!,
            idBack: _idBack,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pièce d\'identité'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conseils pour une bonne photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Placez le document sur une surface plane\n'
                          '• Assurez-vous d\'avoir un bon éclairage\n'
                          '• Évitez les reflets et les ombres\n'
                          '• Capturez tout le document',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Front ID
            _buildDocumentSection(
              title: 'Recto (obligatoire)',
              subtitle: 'Face avec votre photo',
              image: _idFront,
              isRequired: true,
              onCapture: () {
                setState(() => _isCapturingFront = true);
                _showImageSourceDialog();
              },
              onRemove: () => setState(() => _idFront = null),
            ),

            const SizedBox(height: 16),

            // Back ID
            _buildDocumentSection(
              title: 'Verso (optionnel)',
              subtitle: 'Si votre document a un verso',
              image: _idBack,
              isRequired: false,
              onCapture: () {
                setState(() => _isCapturingFront = false);
                _showImageSourceDialog();
              },
              onRemove: () => setState(() => _idBack = null),
            ),

            const SizedBox(height: 32),

            // Continue button
            ElevatedButton(
              onPressed: _idFront != null ? _proceedToSelfie : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: AppTheme.background,
                disabledBackgroundColor:
                    AppTheme.textTertiary.withValues(alpha: 0.3),
                disabledForegroundColor: AppTheme.textTertiary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continuer vers le selfie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required String subtitle,
    required File? image,
    required bool isRequired,
    required VoidCallback onCapture,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Requis',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (image != null)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 24,
                  ),
              ],
            ),
          ),
          if (image != null) ...[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.file(
                    image,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _buildImageActionButton(
                          icon: Icons.refresh,
                          onTap: onCapture,
                          tooltip: 'Reprendre',
                        ),
                        const SizedBox(width: 8),
                        _buildImageActionButton(
                          icon: Icons.delete_outline,
                          onTap: onRemove,
                          tooltip: 'Supprimer',
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: onCapture,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajouter une photo',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isDestructive ? AppTheme.error : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget wrapper to pass arguments to SelfieCapturePageArgs
class SelfieCapturePageArgs extends StatelessWidget {
  final File idFront;
  final File? idBack;

  const SelfieCapturePageArgs({
    super.key,
    required this.idFront,
    this.idBack,
  });

  @override
  Widget build(BuildContext context) {
    return SelfieCapturePageContent(
      idFront: idFront,
      idBack: idBack,
    );
  }
}
