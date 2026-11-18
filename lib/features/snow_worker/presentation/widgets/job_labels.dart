import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/worker_job.dart';

/// Libelle d'une option de service, le meme partout cote deneigeur.
String serviceOptionLabel(AppLocalizations l10n, ServiceOption option) {
  switch (option) {
    case ServiceOption.windowScraping:
      return l10n.option_windowScraping;
    case ServiceOption.doorDeicing:
      return l10n.option_doorDeicing;
    case ServiceOption.wheelClearance:
      return l10n.option_wheelClearance;
    case ServiceOption.roofClearing:
      return l10n.option_roofClearing;
    case ServiceOption.saltSpreading:
      return l10n.option_saltSpreading;
    case ServiceOption.lightsCleaning:
      return l10n.option_lightsCleaning;
    case ServiceOption.perimeterClearance:
      return l10n.option_perimeterClearance;
    case ServiceOption.exhaustCheck:
      return l10n.option_exhaustCheck;
  }
}

/// Ou trouver la voiture sur place : numero de place ou indication du client.
String? jobSpotLabel(AppLocalizations l10n, WorkerJob job) {
  final spot = job.parkingSpotNumber?.trim();
  if (spot != null && spot.isNotEmpty) return l10n.activeJ_spot(spot);
  final custom = job.customLocation?.trim();
  if (custom != null && custom.isNotEmpty) return custom;
  return null;
}
