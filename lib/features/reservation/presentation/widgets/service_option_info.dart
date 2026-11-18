import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Nom, description, icone et prix d'une option : une seule source pour
/// l'ecran Options et le recapitulatif.
({String title, String description, IconData icon, double price})
    serviceOptionInfo(AppLocalizations l10n, ServiceOption option) {
  final (String title, String description, IconData icon, double price) =
      switch (option) {
    ServiceOption.windowScraping => (
        l10n.option_windowScraping,
        l10n.option_windowScrapingDesc,
        Icons.cleaning_services_rounded,
        AppConfig.iceRemovalSurcharge,
      ),
    ServiceOption.doorDeicing => (
        l10n.option_doorDeicing,
        l10n.option_doorDeicingDesc,
        Icons.door_front_door_rounded,
        AppConfig.doorDeicingSurcharge,
      ),
    ServiceOption.wheelClearance => (
        l10n.option_wheelClearance,
        l10n.option_wheelClearanceDesc,
        Icons.tire_repair_rounded,
        AppConfig.wheelClearanceSurcharge,
      ),
    ServiceOption.roofClearing => (
        l10n.option_roofClearing,
        l10n.option_roofClearingDesc,
        Icons.directions_car_filled_rounded,
        AppConfig.roofClearingSurcharge,
      ),
    ServiceOption.saltSpreading => (
        l10n.option_saltSpreading,
        l10n.option_saltSpreadingDesc,
        Icons.grain_rounded,
        AppConfig.saltSpreadingSurcharge,
      ),
    ServiceOption.lightsCleaning => (
        l10n.option_lightsCleaning,
        l10n.option_lightsCleaningDesc,
        Icons.highlight_rounded,
        AppConfig.lightsCleaningSurcharge,
      ),
    ServiceOption.perimeterClearance => (
        l10n.option_perimeterClearance,
        l10n.option_perimeterClearanceDesc,
        Icons.crop_free_rounded,
        AppConfig.perimeterClearanceSurcharge,
      ),
    ServiceOption.exhaustCheck => (
        l10n.option_exhaustCheck,
        l10n.option_exhaustCheckDesc,
        Icons.air_rounded,
        AppConfig.exhaustCheckSurcharge,
      ),
  };
  return (title: title, description: description, icon: icon, price: price);
}

/// Tranche de neige proposee, et la valeur envoyee au calcul du prix.
class SnowRange {
  final String Function(AppLocalizations) label;
  final int? cm;
  final bool Function(int? cm) matches;
  const SnowRange(this.label, this.cm, this.matches);
}

/// Valeur au milieu de chaque tranche ; au-dela de 15 cm, souffleuse requise.
final snowRanges = [
  SnowRange((l) => l.snow_unknown, null, (cm) => cm == null),
  SnowRange((l) => l.snow_under10, 5, (cm) => cm != null && cm < 10),
  SnowRange(
      (l) => l.snow_10to20, 15, (cm) => cm != null && cm >= 10 && cm < 20),
  SnowRange(
      (l) => l.snow_20to30, 25, (cm) => cm != null && cm >= 20 && cm < 30),
  SnowRange((l) => l.snow_over30, 40, (cm) => cm != null && cm >= 30),
];

/// Libelle de la tranche correspondant a une quantite de neige.
String snowRangeLabel(AppLocalizations l10n, int? cm) =>
    snowRanges.firstWhere((r) => r.matches(cm)).label(l10n);
