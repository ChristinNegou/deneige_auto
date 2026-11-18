import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Reponse du defendeur (le deneigeur, le plus souvent) a un litige : la
/// plainte, sa version, et ses photos. Les photos sont envoyees au serveur
/// avant la reponse, puis jointes a celle-ci.
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
  /// 10 photos : la limite du serveur (upload-photos). 50 caracteres : une
  /// vraie explication (le serveur en exige 20).
  static const _maxPhotos = 10;
  static const _minChars = 50;

  final _responseController = TextEditingController();
  final _picker = ImagePicker();
  late final DisputeService _disputeService;

  final List<File> _photos = [];
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
    _responseController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  bool get _deadlinePassed =>
      widget.responseDeadline != null &&
      DateTime.now().isAfter(widget.responseDeadline!);

  int get _length => _responseController.text.trim().length;

  bool get _canSend => !_sending && !_deadlinePassed && _length >= _minChars;

  String get _locale =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en_CA' : 'fr_CA';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) setState(() => _photos.add(File(image.path)));
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _error = AppLocalizations.of(context)!.dispute_imageLoadError);
    }
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
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.textPrimary),
                title: Text(l10n.dispute_chooseFromGallery),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
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
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // Les photos d'abord : la reponse reference leurs adresses
      final photoUrls = await _disputeService.uploadPhotos(_photos);
      await _disputeService.respondToDispute(
        disputeId: widget.disputeId,
        text: _responseController.text.trim(),
        photos: photoUrls.isEmpty ? null : photoUrls,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.disputeR_sent,
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
        _error = disputeErrorMessage(e, l10n.dispute_responseError);
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
          title: Text(l10n.dispute_respondTitle, style: AppTheme.labelMedium),
          centerTitle: true,
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(l10n.disputeR_intro,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.textSecondary)),
            if (widget.responseDeadline != null) ...[
              const SizedBox(height: 10),
              _deadlineLine(l10n),
            ],
            const SizedBox(height: 20),
            _ComplaintCard(
              typeLabel: widget.disputeType,
              description: widget.disputeDescription,
              title: l10n.disputeD_complaint,
            ),
            const SizedBox(height: 24),
            Text(l10n.dispute_yourResponse, style: AppTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _responseController,
              enabled: !_sending && !_deadlinePassed,
              minLines: 5,
              maxLines: 10,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.dispute_responseHint,
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
                // Le compteur indique le minimum tant qu'il n'est pas atteint
                counterText: _length < _minChars
                    ? l10n.disputeR_minChars(_minChars, _length)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.dispute_photosEvidence, style: AppTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(l10n.disputeR_photosHelp(_maxPhotos),
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _buildPhotoGrid(l10n),
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton(
              onPressed: _canSend ? _send : null,
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
                  : Text(_deadlinePassed
                      ? l10n.dispute_responseDeadlinePassed
                      : l10n.dispute_sendResponse),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deadlineLine(AppLocalizations l10n) {
    final passed = _deadlinePassed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.schedule_rounded,
            size: 18, color: passed ? AppTheme.error : AppTheme.textPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            passed
                ? l10n.disputeD_yourTurnLate
                : l10n.disputeR_deadline(
                    DateFormat('EEEE d MMMM, HH:mm', _locale)
                        .format(widget.responseDeadline!)),
            style: AppTheme.bodyMedium.copyWith(
              color: passed ? AppTheme.error : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(AppLocalizations l10n) {
    final tiles = <Widget>[
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
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: tiles,
    );
  }
}

/// La plainte, telle que le client l'a ecrite.
class _ComplaintCard extends StatelessWidget {
  final String title;
  final String typeLabel;
  final String description;

  const _ComplaintCard({
    required this.title,
    required this.typeLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(typeLabel, style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(description,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppTheme.textPrimary, height: 1.4)),
        ],
      ),
    );
  }
}
