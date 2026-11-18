import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/address_search_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../bloc/new_reservation_bloc.dart';
import '../../bloc/new_reservation_event.dart';
import '../../bloc/new_reservation_state.dart';

/// Etape Adresse : la position GPS remplit l'adresse toute seule ; sinon on
/// cherche l'adresse et on la choisit dans les suggestions. Pas de bouton
/// "valider" : choisir une suggestion suffit.
class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

enum _SearchStatus { idle, searching, done, failed }

class _Step2LocationScreenState extends State<Step2LocationScreen>
    with WidgetsBindingObserver {
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AddressSearchService _search = sl<AddressSearchService>();

  Timer? _debounce;
  int _requestId = 0;
  List<AddressSuggestion> _suggestions = const [];
  _SearchStatus _status = _SearchStatus.idle;

  /// Derniere position connue : classe les suggestions par proximite.
  double? _biasLat;
  double? _biasLon;

  NewReservationBloc get _bloc => context.read<NewReservationBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _bloc.state;
      if (state.locationAddress != null) {
        _addressController.text = state.locationAddress!;
      }
      if (!state.hasValidLocation && !state.isGettingLocation) {
        _bloc.add(GetCurrentLocation());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _addressController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Au retour des reglages (GPS active, permission accordee), on reessaie.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed || !mounted) return;
    final state = _bloc.state;
    if (state.locationIssue != null &&
        !state.hasValidLocation &&
        !state.isGettingLocation) {
      _bloc.add(GetCurrentLocation());
    }
  }

  void _onQueryChanged(String value) {
    // L'adresse ne correspond plus a la position enregistree
    if (value.trim() != _bloc.state.locationAddress) {
      _bloc.add(ClearLocation());
    }
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
        latitude: _biasLat,
        longitude: _biasLon,
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
    _addressController.text = s.fullAddress;
    _focusNode.unfocus();
    setState(() {
      _suggestions = const [];
      _status = _SearchStatus.idle;
    });
    _bloc.add(SetLocationFromSuggestion(
      address: s.fullAddress,
      latitude: s.latitude,
      longitude: s.longitude,
    ));
  }

  /// Touche Entree : premiere suggestion, sinon recherche classique.
  void _onSubmitted(String value) {
    if (_suggestions.isNotEmpty) {
      _select(_suggestions.first);
    } else if (value.trim().length >= 3) {
      _bloc.add(SetLocationFromAddress(value.trim()));
    }
  }

  void _clear() {
    _debounce?.cancel();
    _requestId++;
    _addressController.clear();
    _bloc.add(ClearLocation());
    setState(() {
      _suggestions = const [];
      _status = _SearchStatus.idle;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<NewReservationBloc, NewReservationState>(
      listenWhen: (prev, curr) =>
          prev.locationAddress != curr.locationAddress ||
          prev.locationLatitude != curr.locationLatitude,
      listener: (context, state) {
        if (state.hasValidLocation) {
          _biasLat = state.locationLatitude;
          _biasLon = state.locationLongitude;
        }
        // Adresse trouvee par le GPS : on l'affiche si l'utilisateur ne tape pas
        if (state.locationAddress != null &&
            !_focusNode.hasFocus &&
            _addressController.text != state.locationAddress) {
          _addressController.text = state.locationAddress!;
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.step2_subtitle,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              if (state.locationIssue != null && !state.hasValidLocation) ...[
                _buildGpsBanner(context, state.locationIssue!),
                const SizedBox(height: 16),
              ],
              _buildSearchField(context, state),
              _buildSearchFeedback(context, state),
              if (state.locationIssue == null || state.hasValidLocation) ...[
                const SizedBox(height: 8),
                _buildUseMyLocation(context, state),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Un seul message, et l'action qui regle le probleme.
  Widget _buildGpsBanner(BuildContext context, LocationIssue issue) {
    final l10n = AppLocalizations.of(context)!;
    final (String message, String action, VoidCallback onPressed) =
        switch (issue) {
      LocationIssue.serviceDisabled => (
          l10n.step2_gpsOff,
          l10n.step2_enableGps,
          () => Geolocator.openLocationSettings(),
        ),
      LocationIssue.permissionDenied => (
          l10n.step2_gpsDenied,
          l10n.step2_allow,
          () => _bloc.add(GetCurrentLocation()),
        ),
      LocationIssue.permissionDeniedForever => (
          l10n.step2_gpsDenied,
          l10n.step2_openSettings,
          () => Geolocator.openAppSettings(),
        ),
      LocationIssue.unavailable => (
          l10n.step2_gpsUnavailable,
          l10n.step2_retry,
          () => _bloc.add(GetCurrentLocation()),
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded,
              size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(action,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, NewReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final hasAddress = state.hasValidLocation;
    final busy = _status == _SearchStatus.searching ||
        (state.isGettingLocation && _focusNode.hasFocus);

    return TextField(
      controller: _addressController,
      focusNode: _focusNode,
      style:
          TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: l10n.step2_searchHint,
        hintStyle: TextStyle(
            color: AppTheme.textTertiary, fontWeight: FontWeight.w400),
        // L'epingle pleine indique qu'une adresse est enregistree
        prefixIcon: Icon(
          hasAddress ? Icons.location_on_rounded : Icons.search_rounded,
          color: hasAddress ? AppTheme.primary : AppTheme.textTertiary,
        ),
        suffixIcon: busy
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.textSecondary),
                ),
              )
            : _addressController.text.isNotEmpty
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
      onChanged: _onQueryChanged,
      onSubmitted: _onSubmitted,
    );
  }

  /// Suggestions, ou une phrase qui dit quoi faire.
  Widget _buildSearchFeedback(BuildContext context, NewReservationState state) {
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
    } else if (state.locationError != null) {
      hint = state.locationError;
    } else if (!state.hasValidLocation &&
        _addressController.text.trim().length >= 3 &&
        _status == _SearchStatus.idle &&
        !state.isGettingLocation) {
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

  Widget _buildUseMyLocation(BuildContext context, NewReservationState state) {
    final l10n = AppLocalizations.of(context)!;
    final locating = state.isGettingLocation;

    return TextButton.icon(
      onPressed: locating
          ? null
          : () {
              _focusNode.unfocus();
              _bloc.add(GetCurrentLocation());
            },
      icon: locating
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.textSecondary),
            )
          : Icon(Icons.my_location_rounded, size: 18, color: AppTheme.primary),
      label: Text(
        locating ? l10n.step2_locating : l10n.step2_useMyLocation,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: locating ? AppTheme.textSecondary : AppTheme.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
    );
  }
}
