/// Estimation de prix IA
class PriceEstimation {
  final double basePrice;
  final double priceBeforeTax;
  final PriceTaxes taxes;
  final double suggestedPrice;
  final PriceRange priceRange;
  final PriceMultipliers multipliers;
  final List<PriceAdjustment> adjustments;
  final TimeEstimation? timeEstimation;
  final String? reasoning;
  final DateTime calculatedAt;

  const PriceEstimation({
    required this.basePrice,
    required this.priceBeforeTax,
    required this.taxes,
    required this.suggestedPrice,
    required this.priceRange,
    required this.multipliers,
    required this.adjustments,
    this.timeEstimation,
    this.reasoning,
    required this.calculatedAt,
  });

  factory PriceEstimation.fromJson(Map<String, dynamic> json) {
    return PriceEstimation(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      priceBeforeTax: (json['priceBeforeTax'] as num?)?.toDouble() ?? 0,
      taxes: PriceTaxes.fromJson(json['taxes'] as Map<String, dynamic>? ?? {}),
      suggestedPrice: (json['suggestedPrice'] as num?)?.toDouble() ?? 0,
      priceRange: PriceRange.fromJson(
          json['priceRange'] as Map<String, dynamic>? ?? {}),
      multipliers: PriceMultipliers.fromJson(
          json['multipliers'] as Map<String, dynamic>? ?? {}),
      adjustments: (json['adjustments'] as List<dynamic>?)
              ?.map((e) => PriceAdjustment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeEstimation: json['timeEstimation'] != null
          ? TimeEstimation.fromJson(
              json['timeEstimation'] as Map<String, dynamic>)
          : null,
      reasoning: json['reasoning'] as String?,
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Vérifie si des majorations sont appliquées
  bool get hasAdjustments => adjustments.isNotEmpty;

  /// Total des majorations
  double get totalAdjustments =>
      adjustments.fold(0, (sum, adj) => sum + adj.amount);

  /// Vérifie si l'estimation de temps est disponible
  bool get hasTimeEstimation => timeEstimation != null;
}

/// Estimation du temps de déneigement
class TimeEstimation {
  final int estimatedMinutes;
  final TimeRange timeRange;
  final TimeBreakdown breakdown;

  const TimeEstimation({
    required this.estimatedMinutes,
    required this.timeRange,
    required this.breakdown,
  });

  factory TimeEstimation.fromJson(Map<String, dynamic> json) {
    return TimeEstimation(
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 10,
      timeRange:
          TimeRange.fromJson(json['timeRange'] as Map<String, dynamic>? ?? {}),
      breakdown: TimeBreakdown.fromJson(
          json['breakdown'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Formatte le temps estimé pour l'affichage
  String get formattedTime {
    if (estimatedMinutes < 60) {
      return '$estimatedMinutes min';
    }
    final hours = estimatedMinutes ~/ 60;
    final mins = estimatedMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
  }

  /// Formatte la fourchette de temps
  String get formattedRange => '${timeRange.min}-${timeRange.max} min';
}

class TimeRange {
  final int min;
  final int max;

  const TimeRange({required this.min, required this.max});

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      min: (json['min'] as num?)?.toInt() ?? 8,
      max: (json['max'] as num?)?.toInt() ?? 15,
    );
  }
}

class TimeBreakdown {
  final int baseTime;
  final double snowMultiplier;
  final int optionsTime;
  final String vehicleType;

  const TimeBreakdown({
    required this.baseTime,
    required this.snowMultiplier,
    required this.optionsTime,
    required this.vehicleType,
  });

  factory TimeBreakdown.fromJson(Map<String, dynamic> json) {
    return TimeBreakdown(
      baseTime: (json['baseTime'] as num?)?.toInt() ?? 10,
      snowMultiplier: (json['snowMultiplier'] as num?)?.toDouble() ?? 1.0,
      optionsTime: (json['optionsTime'] as num?)?.toInt() ?? 0,
      vehicleType: json['vehicleType'] as String? ?? 'unknown',
    );
  }

  /// Label du type de véhicule en français
  String get vehicleTypeLabel {
    switch (vehicleType) {
      case 'compact':
        return 'Compacte';
      case 'sedan':
        return 'Berline';
      case 'suv':
        return 'VUS';
      case 'truck':
        return 'Camion';
      case 'minivan':
        return 'Fourgonnette';
      default:
        return 'Véhicule';
    }
  }
}

class PriceTaxes {
  final double tps;
  final double tvq;

  const PriceTaxes({required this.tps, required this.tvq});

  factory PriceTaxes.fromJson(Map<String, dynamic> json) {
    return PriceTaxes(
      tps: (json['tps'] as num?)?.toDouble() ?? 0,
      tvq: (json['tvq'] as num?)?.toDouble() ?? 0,
    );
  }

  double get total => tps + tvq;
}

class PriceRange {
  final double min;
  final double max;

  const PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PriceMultipliers {
  final double urgency;
  final double weather;
  final double demand;
  final double location;
  final double total;

  const PriceMultipliers({
    required this.urgency,
    required this.weather,
    required this.demand,
    required this.location,
    required this.total,
  });

  factory PriceMultipliers.fromJson(Map<String, dynamic> json) {
    return PriceMultipliers(
      urgency: (json['urgency'] as num?)?.toDouble() ?? 1.0,
      weather: (json['weather'] as num?)?.toDouble() ?? 1.0,
      demand: (json['demand'] as num?)?.toDouble() ?? 1.0,
      location: (json['location'] as num?)?.toDouble() ?? 1.0,
      total: (json['total'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Vérifie si des multiplicateurs sont actifs
  bool get hasActiveMultipliers =>
      urgency > 1 || weather > 1 || demand > 1 || location > 1;
}

class PriceAdjustment {
  final String type;
  final double amount;
  final String reason;

  const PriceAdjustment({
    required this.type,
    required this.amount,
    required this.reason,
  });

  factory PriceAdjustment.fromJson(Map<String, dynamic> json) {
    return PriceAdjustment(
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }

  /// Icône selon le type
  String get icon {
    switch (type) {
      case 'urgency':
        return '⏱️';
      case 'weather':
        return '🌨️';
      case 'demand':
        return '📈';
      case 'location':
        return '📍';
      default:
        return '💰';
    }
  }
}
