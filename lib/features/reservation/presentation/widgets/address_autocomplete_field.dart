import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/address_search_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

enum _SearchStatus { idle, searching, done, failed }

/// Champ d'adresse avec suggestions pendant la saisie. Une adresse n'est
/// retenue que lorsqu'on choisit une suggestion (elle arrive geolocalisee) :
/// un texte libre ne suffit pas.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Adresse actuellement retenue (null : aucune).
  final String? confirmedAddress;

  /// Une operation externe est en cours (ex. recherche GPS).
  final bool busy;

  /// Position servant a classer les suggestions par proximite.
  final double? biasLatitude;
  final double? biasLongitude;

  /// Le client a choisi une suggestion.
  final ValueChanged<AddressSuggestion> onSelected;

  /// Le texte ne correspond plus a l'adresse retenue.
  final VoidCallback onEdited;

  /// Entree sans suggestion : recherche de secours (facultatif).
  final ValueChanged<String>? onSubmitFreeText;

  /// Message de l'ecran parent, affiche quand le champ n'a rien a dire.
  final String? externalHint;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.confirmedAddress,
    required this.onSelected,
    required this.onEdited,
    this.busy = false,
    this.biasLatitude,
    this.biasLongitude,
    this.onSubmitFreeText,
    this.externalHint,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final AddressSearchService _search = sl<AddressSearchService>();

  Timer? _debounce;
  int _requestId = 0;
  List<AddressSuggestion> _suggestions = const [];
  _SearchStatus _status = _SearchStatus.idle;

  bool get _confirmed =>
      widget.confirmedAddress != null &&
      widget.controller.text.trim() == widget.confirmedAddress;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.trim() != widget.confirmedAddress) widget.onEdited();
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _status = _SearchStatus.idle;
      });
      return;
    }
    setState(() => _status = _SearchStatus.searching);
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final id = ++_requestId;
    final language = Localizations.localeOf(context).languageCode;
    try {
      final results = await _search.search(
        query,
        latitude: widget.biasLatitude,
        longitude: widget.biasLongitude,
        language: language,
      );
      // Une frappe plus recente a deja relance une recherche
      if (!mounted || id != _requestId) return;
      setState(() {
        _suggestions = results;
        _status = _SearchStatus.done;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _suggestions = const [];
        _status = _SearchStatus.failed;
      });
    }
  }

  void _select(AddressSuggestion s) {
    _debounce?.cancel();
    _requestId++;
    widget.controller.text = s.fullAddress;
    widget.focusNode.unfocus();
    setState(() {
      _suggestions = const [];
      _status = _SearchStatus.idle;
    });
    widget.onSelected(s);
  }

  /// Touche Entree : premiere suggestion, sinon recherche de secours.
  void _onSubmitted(String value) {
    if (_suggestions.isNotEmpty) {
      _select(_suggestions.first);
    } else if (value.trim().length >= 3) {
      widget.onSubmitFreeText?.call(value.trim());
    }
  }

  void _clear() {
    _debounce?.cancel();
    _requestId++;
    widget.controller.clear();
    widget.onEdited();
    setState(() {
      _suggestions = const [];
      _status = _SearchStatus.idle;
    });
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(context),
        _buildFeedback(context),
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _status == _SearchStatus.searching || widget.busy;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style:
          TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: l10n.step2_searchHint,
        hintStyle: TextStyle(
            color: AppTheme.textTertiary, fontWeight: FontWeight.w400),
        // L'epingle pleine indique qu'une adresse est retenue
        prefixIcon: Icon(
          _confirmed ? Icons.location_on_rounded : Icons.search_rounded,
          color: _confirmed ? AppTheme.primary : AppTheme.textTertiary,
        ),
        suffixIcon: busy
            ? Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.textSecondary),
                ),
              )
            : widget.controller.text.isNotEmpty
                ? IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: Icon(Icons.close_rounded,
                        color: AppTheme.textTertiary, size: 20),
                    onPressed: _clear,
                  )
                : null,
        filled: true,
        fillColor: AppTheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: _onChanged,
      onSubmitted: _onSubmitted,
    );
  }

  /// Suggestions, ou une phrase qui dit quoi faire.
  Widget _buildFeedback(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_suggestions.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < _suggestions.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppTheme.border),
              _buildSuggestion(_suggestions[i]),
            ],
          ],
        ),
      );
    }

    String? hint;
    if (_status == _SearchStatus.failed) {
      hint = l10n.step2_searchFailed;
    } else if (_status == _SearchStatus.done) {
      hint = l10n.step2_noResults;
    } else if (widget.externalHint != null) {
      hint = widget.externalHint;
    } else if (!_confirmed &&
        widget.controller.text.trim().length >= 3 &&
        _status == _SearchStatus.idle &&
        !widget.busy) {
      hint = l10n.step2_selectSuggestion;
    }
    if (hint == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        hint,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildSuggestion(AddressSuggestion s) {
    return InkWell(
      onTap: () => _select(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 20, color: AppTheme.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.primary,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (s.secondary.isNotEmpty)
                    Text(
                      s.secondary,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
