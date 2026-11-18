import 'package:equatable/equatable.dart';

import 'worker_job.dart';

/// Resultat de la recherche de travaux disponibles.
/// En plus des travaux compatibles, indique combien de travaux a proximite
/// ont ete masques parce que le deneigeur n'a pas l'equipement requis.
class AvailableJobs extends Equatable {
  final List<WorkerJob> jobs;

  /// Nombre de travaux masques faute d'equipement.
  final int hiddenForEquipmentCount;

  /// Equipement qui manque au deneigeur pour voir ces travaux.
  final List<EquipmentType> missingEquipment;

  const AvailableJobs({
    required this.jobs,
    this.hiddenForEquipmentCount = 0,
    this.missingEquipment = const [],
  });

  @override
  List<Object?> get props => [jobs, hiddenForEquipmentCount, missingEquipment];
}
