import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../bloc/verification_bloc.dart';
import '../bloc/verification_event.dart';
import '../bloc/verification_state.dart';

class SelfieCapturePageContent extends StatefulWidget {
  final File idFront;
  final File? idBack;

  const SelfieCapturePageContent({
    super.key,
    required this.idFront,
    this.idBack,
  });

  @override
  State<SelfieCapturePageContent> createState() =>
      _SelfieCapturePageContentState();
}

class _SelfieCapturePageContentState extends State<SelfieCapturePageContent> {
  final ImagePicker _picker = ImagePicker();
  File? _selfie;

  Future<void> _captureSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selfie = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.common_error}: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _submitVerification() {
    if (_selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.verification_selfieRequired),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    context.read<VerificationBloc>().add(
          SubmitVerification(
            idFront: widget.idFront,
            idBack: widget.idBack,
            selfie: _selfie!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.verification_selfie),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: BlocListener<VerificationBloc, VerificationState>(
        listener: (context, state) {
          if (state is VerificationSubmitted) {
            // Pop back to the verification page
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is VerificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
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
                    Icon(Icons.face, color: AppTheme.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .verification_takeSelfie,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!
                                .verification_selfieInstructions,
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

              // Selfie preview or capture button
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .verification_yourSelfie,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!
                                      .verification_selfieFaceComparison,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selfie != null)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                    if (_selfie != null) ...[
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Image.file(
                              _selfie!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: _captureSelfie,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .verification_retake,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      InkWell(
                        onTap: _captureSelfie,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Container(
                          height: 250,
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
                              // Face outline
                              Container(
                                width: 120,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.primary,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 64,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: AppTheme.background,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .verification_takeSelfieBtn,
                                      style: TextStyle(
                                        color: AppTheme.background,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Summary of documents
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.verification_summary,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryItem(
                      icon: Icons.badge,
                      label: AppLocalizations.of(context)!.verification_idFront,
                      isComplete: true,
                    ),
                    if (widget.idBack != null)
                      _buildSummaryItem(
                        icon: Icons.badge_outlined,
                        label:
                            AppLocalizations.of(context)!.verification_idBack,
                        isComplete: true,
                      ),
                    _buildSummaryItem(
                      icon: Icons.face,
                      label: AppLocalizations.of(context)!.verification_selfie,
                      isComplete: _selfie != null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              BlocBuilder<VerificationBloc, VerificationState>(
                builder: (context, state) {
                  final isSubmitting = state is VerificationSubmitting;

                  return ElevatedButton(
                    onPressed: _selfie != null && !isSubmitting
                        ? _submitVerification
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.textTertiary.withValues(alpha: 0.3),
                      disabledForegroundColor: AppTheme.textTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!
                                    .verification_submitForVerification,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Privacy note
              Text(
                AppLocalizations.of(context)!.verification_privacyNote,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required bool isComplete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isComplete ? AppTheme.success : AppTheme.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color:
                    isComplete ? AppTheme.textPrimary : AppTheme.textTertiary,
              ),
            ),
          ),
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isComplete ? AppTheme.success : AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }
}
