import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Ajout de preuves a un litige ouvert (client ou deneigeur) : des photos et
/// une courte explication. Le serveur range celles du defendeur avec sa
/// reponse et celles du plaignant avec sa plainte.
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
  /// La limite du serveur (upload-photos).
  static const _maxPhotos = 10;

  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  late final DisputeService _disputeService;

  final List<File> _photos = [];
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Plus de preuves une fois la decision rendue.
  bool get _open => !['resolved', 'closed'].contains(widget.disputeStatus);

  bool get _hasContent =>
      _photos.isNotEmpty || _descriptionController.text.trim().isNotEmpty;

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) setState(() => _photos.add(File(image.path)));
    } catch (_) {
      _showPickError();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      final room = _maxPhotos - _photos.length;
      setState(
          () => _photos.addAll(images.take(room).map((x) => File(x.path))));
    } catch (_) {
      _showPickError();
    }
  }

  void _showPickError() {
    if (!mounted) return;
    setState(
        () => _error = AppLocalizations.of(context)!.dispute_imagesLoadError);
  }

  void _chooseSource() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppTheme.textPrimary),
                title: Text(l10n.dispute_takePhoto),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.textPrimary),
                title: Text(l10n.dispute_chooseFromGallery),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasContent) {
      setState(() => _error = l10n.dispute_addPhotoOrDescription);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final photoUrls = await _disputeService.uploadPhotos(_photos);
      final description = _descriptionController.text.trim();
      await _disputeService.addEvidence(
        disputeId: widget.disputeId,
        photos: photoUrls.isEmpty ? null : photoUrls,
        description: description.isEmpty ? null : description,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dispute_evidenceAddedMessage,
              style: const TextStyle(color: AppTheme.onPrimary)),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = disputeErrorMessage(e, l10n.dispute_addEvidenceError);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(l10n.dispute_addEvidence, style: AppTheme.labelMedium),
          centerTitle: true,
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (!_open)
              Text(l10n.dispute_resolvedCannotAddEvidence,
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.error))
            else ...[
              Text(l10n.dispute_photosLabel, style: AppTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(l10n.disputeR_photosHelp(_maxPhotos),
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              _buildPhotoGrid(l10n),
              const SizedBox(height: 24),
              Text(l10n.dispute_descriptionOptional,
                  style: AppTheme.headlineSmall),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                enabled: !_sending,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.dispute_describeEvidenceHint,
                  filled: true,
                  fillColor: AppTheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 18, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style:
                            AppTheme.bodySmall.copyWith(color: AppTheme.error)),
                  ),
                ],
              ),
            ],
          ],
        ),
        bottomNavigationBar: !_open
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton(
                    onPressed: _sending || !_hasContent ? null : _send,
                    child: _sending
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.onPrimary),
                              ),
                              const SizedBox(width: 10),
                              Text(l10n.disputeR_sending),
                            ],
                          )
                        : Text(l10n.dispute_submitEvidence),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPhotoGrid(AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        for (var i = 0; i < _photos.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                child: Image.file(_photos[i], fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: AppTheme.primary.withValues(alpha: 0.75),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending
                        ? null
                        : () => setState(() => _photos.removeAt(i)),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: AppTheme.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (_photos.length < _maxPhotos)
          Material(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              onTap: _sending ? null : _chooseSource,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: AppTheme.textPrimary),
                  const SizedBox(height: 6),
                  Text(
                    l10n.disputeR_addPhoto,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
