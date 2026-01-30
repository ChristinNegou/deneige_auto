import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Écran de création d'un litige général
class CreateDisputePage extends StatefulWidget {
  final String reservationId;
  final String? workerName;
  final double totalPrice;
  final DateTime? serviceDate;

  const CreateDisputePage({
    super.key,
    required this.reservationId,
    this.workerName,
    required this.totalPrice,
    this.serviceDate,
  });

  @override
  State<CreateDisputePage> createState() => _CreateDisputePageState();
}

class _CreateDisputePageState extends State<CreateDisputePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late DisputeService _disputeService;
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  DisputeType _selectedType = DisputeType.qualityIssue;
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

  // Types disponibles (exclure noShow qui a son propre écran)
  final List<DisputeType> _availableTypes =
      DisputeType.values.where((t) => t != DisputeType.noShow).toList();

  @override
  void initState() {
    super.initState();
    _disputeService = DisputeService(dioClient: sl<DioClient>());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dispute_imageLoadError),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.dispute_addPhoto,
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
                  l10n.vehicle_takePhoto,
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
                  l10n.dispute_chooseFromGallery,
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

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      double? claimedAmount;
      if (_amountController.text.isNotEmpty) {
        claimedAmount = double.tryParse(_amountController.text);
      }

      // Capture de la position GPS (non-bloquant si échec)
      Map<String, double>? gpsLocation;
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        gpsLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }

      // Upload des photos vers Cloudinary et récupérer les URLs
      List<String>? photoUrls;
      if (_photos.isNotEmpty) {
        photoUrls = await _disputeService.uploadPhotos(_photos);
      }

      final result = await _disputeService.createDispute(
        reservationId: widget.reservationId,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        claimedAmount: claimedAmount,
        photos: photoUrls,
        gpsLocation: gpsLocation,
      );

      if (!mounted) return;

      _showSuccessDialog(result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Exception:')
                ? e.toString().replaceFirst('Exception: ', '')
                : l10n.dispute_createError,
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

  void _showSuccessDialog(Map<String, dynamic> result) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.dispute_created,
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
              l10n.dispute_submitSuccess,
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
                  Icon(Icons.schedule, color: AppTheme.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.dispute_workerResponseDeadline,
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
            child: Text(l10n.common_understood),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          l10n.dispute_reportProblem,
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
                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 24),

                // Type de litige
                _buildSectionTitle(l10n.dispute_problemType),
                const SizedBox(height: 12),
                _buildTypeSelector(),
                const SizedBox(height: 24),

                // Description
                _buildSectionTitle(l10n.common_description),
                const SizedBox(height: 12),
                _buildDescriptionField(),
                const SizedBox(height: 24),

                // Montant réclamé (optionnel)
                _buildSectionTitle(l10n.dispute_claimedAmountOptional),
                const SizedBox(height: 12),
                _buildAmountField(),
                const SizedBox(height: 24),

                // Photos
                _buildSectionTitle(l10n.dispute_photosEvidence),
                const SizedBox(height: 12),
                _buildPhotoSection(),
                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final l10n = AppLocalizations.of(context)!;
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.gavel, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dispute_reservation,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '#${widget.reservationId.substring(widget.reservationId.length - 8)}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.dispute_amountPaid,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${widget.totalPrice.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.workerName != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppTheme.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.dispute_workerNameLabel(widget.workerName!),
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
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

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonFormField<DisputeType>(
        value: _selectedType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(Icons.category, color: AppTheme.primary),
        ),
        dropdownColor: AppTheme.surface,
        style: TextStyle(color: AppTheme.textPrimary),
        items: _availableTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.label),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedType = value);
          }
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      maxLength: 1000,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.dispute_describeInDetail,
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
          return l10n.dispute_describeRequired;
        }
        if (value.trim().length < 20) {
          return l10n.dispute_descriptionTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ex: 25.00',
        hintStyle: TextStyle(color: AppTheme.textTertiary),
        prefixIcon: Icon(Icons.attach_money, color: AppTheme.primary),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        helperText: 'Maximum: ${widget.totalPrice.toStringAsFixed(2)} \$',
        helperStyle: TextStyle(color: AppTheme.textTertiary),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final amount = double.tryParse(value);
          if (amount == null) {
            return l10n.dispute_invalidAmount;
          }
          if (amount > widget.totalPrice) {
            return l10n.dispute_amountExceedsPaid;
          }
          if (amount <= 0) {
            return l10n.dispute_amountMustBePositive;
          }
        }
        return null;
      },
    );
  }

  Widget _buildPhotoSection() {
    final l10n = AppLocalizations.of(context)!;
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
        if (_photos.length < 5)
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _photos.isEmpty
                        ? l10n.dispute_addPhotos
                        : l10n.dispute_addAnotherPhoto,
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
          l10n.dispute_maxPhotosHint,
          style: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitDispute,
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
                l10n.dispute_submit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
