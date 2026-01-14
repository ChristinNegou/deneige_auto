// Helper pour convertir en double (gère String et num)
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// Helper pour convertir en int (gère String et num)
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class StripeReconciliation {
  final ReconciliationPeriod period;
  final LocalDatabaseStats localDatabase;
  final StripeStats stripe;
  final Discrepancies discrepancies;
  final List<ProblematicReservation> problematicReservations;

  StripeReconciliation({
    required this.period,
    required this.localDatabase,
    required this.stripe,
    required this.discrepancies,
    required this.problematicReservations,
  });

  factory StripeReconciliation.fromJson(Map<String, dynamic> json) {
    return StripeReconciliation(
      period: ReconciliationPeriod.fromJson(json['period'] ?? {}),
      localDatabase: LocalDatabaseStats.fromJson(json['localDatabase'] ?? {}),
      stripe: StripeStats.fromJson(json['stripe'] ?? {}),
      discrepancies: Discrepancies.fromJson(json['discrepancies'] ?? {}),
      problematicReservations:
          (json['problematicReservations'] as List<dynamic>?)
                  ?.map((r) => ProblematicReservation.fromJson(r))
                  .toList() ??
              [],
    );
  }

  bool get hasDiscrepancies {
    return discrepancies.revenue.difference.abs() > 0.01 ||
        discrepancies.transactionCount.difference != 0;
  }
}

class ReconciliationPeriod {
  final DateTime start;
  final DateTime end;

  ReconciliationPeriod({required this.start, required this.end});

  factory ReconciliationPeriod.fromJson(Map<String, dynamic> json) {
    return ReconciliationPeriod(
      start: DateTime.tryParse(json['start'] ?? '') ??
          DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.tryParse(json['end'] ?? '') ?? DateTime.now(),
    );
  }
}

class LocalDatabaseStats {
  final double totalRevenue;
  final double platformFeesGross;
  final double platformFeesNet;
  final double workerPayouts;
  final double stripeFees;
  final double tips;
  final int reservationCount;

  LocalDatabaseStats({
    required this.totalRevenue,
    required this.platformFeesGross,
    required this.platformFeesNet,
    required this.workerPayouts,
    required this.stripeFees,
    required this.tips,
    required this.reservationCount,
  });

  factory LocalDatabaseStats.fromJson(Map<String, dynamic> json) {
    return LocalDatabaseStats(
      totalRevenue: _toDouble(json['totalRevenue']),
      platformFeesGross: _toDouble(json['platformFeesGross']),
      platformFeesNet: _toDouble(json['platformFeesNet']),
      workerPayouts: _toDouble(json['workerPayouts']),
      stripeFees: _toDouble(json['stripeFees']),
      tips: _toDouble(json['tips']),
      reservationCount: _toInt(json['reservationCount']),
    );
  }
}

class StripeStats {
  final StripeBalance? balance;
  final double chargesTotal;
  final int chargesCount;
  final double transfersTotal;
  final int transfersCount;
  final double refundsTotal;
  final int refundsCount;
  final double feesTotal;
  final String? error;

  StripeStats({
    this.balance,
    required this.chargesTotal,
    required this.chargesCount,
    required this.transfersTotal,
    required this.transfersCount,
    required this.refundsTotal,
    required this.refundsCount,
    required this.feesTotal,
    this.error,
  });

  factory StripeStats.fromJson(Map<String, dynamic> json) {
    return StripeStats(
      balance: json['balance'] != null
          ? StripeBalance.fromJson(json['balance'])
          : null,
      chargesTotal: _toDouble(json['chargesTotal']),
      chargesCount: _toInt(json['chargesCount']),
      transfersTotal: _toDouble(json['transfersTotal']),
      transfersCount: _toInt(json['transfersCount']),
      refundsTotal: _toDouble(json['refundsTotal']),
      refundsCount: _toInt(json['refundsCount']),
      feesTotal: _toDouble(json['feesTotal']),
      error: json['error']?.toString(),
    );
  }
}

class StripeBalance {
  final double available;
  final double pending;
  final String currency;

  StripeBalance({
    required this.available,
    required this.pending,
    required this.currency,
  });

  factory StripeBalance.fromJson(Map<String, dynamic> json) {
    return StripeBalance(
      available: _toDouble(json['available']),
      pending: _toDouble(json['pending']),
      currency: json['currency']?.toString() ?? 'CAD',
    );
  }
}

class Discrepancies {
  final DiscrepancyDetail revenue;
  final DiscrepancyDetail workerPayouts;
  final DiscrepancyDetail stripeFees;
  final DiscrepancyDetailInt transactionCount;

  Discrepancies({
    required this.revenue,
    required this.workerPayouts,
    required this.stripeFees,
    required this.transactionCount,
  });

  factory Discrepancies.fromJson(Map<String, dynamic> json) {
    return Discrepancies(
      revenue: DiscrepancyDetail.fromJson(json['revenue'] ?? {}),
      workerPayouts: DiscrepancyDetail.fromJson(json['workerPayouts'] ?? {}),
      stripeFees: DiscrepancyDetail.fromJson(json['stripeFees'] ?? {}),
      transactionCount:
          DiscrepancyDetailInt.fromJson(json['transactionCount'] ?? {}),
    );
  }
}

class DiscrepancyDetail {
  final double local;
  final double stripe;
  final double difference;
  final double percentDiff;

  DiscrepancyDetail({
    required this.local,
    required this.stripe,
    required this.difference,
    required this.percentDiff,
  });

  factory DiscrepancyDetail.fromJson(Map<String, dynamic> json) {
    return DiscrepancyDetail(
      local: _toDouble(json['local']),
      stripe: _toDouble(json['stripe']),
      difference: _toDouble(json['difference']),
      percentDiff: _toDouble(json['percentDiff']),
    );
  }
}

class DiscrepancyDetailInt {
  final int local;
  final int stripe;
  final int difference;

  DiscrepancyDetailInt({
    required this.local,
    required this.stripe,
    required this.difference,
  });

  factory DiscrepancyDetailInt.fromJson(Map<String, dynamic> json) {
    return DiscrepancyDetailInt(
      local: _toInt(json['local']),
      stripe: _toInt(json['stripe']),
      difference: _toInt(json['difference']),
    );
  }
}

class ProblematicReservation {
  final String id;
  final double totalPrice;
  final String status;
  final String paymentStatus;
  final String? paymentIntentId;
  final String? payoutStatus;
  final DateTime createdAt;

  ProblematicReservation({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.paymentIntentId,
    this.payoutStatus,
    required this.createdAt,
  });

  factory ProblematicReservation.fromJson(Map<String, dynamic> json) {
    return ProblematicReservation(
      id: json['id']?.toString() ?? '',
      totalPrice: _toDouble(json['totalPrice']),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      paymentIntentId: json['paymentIntentId']?.toString(),
      payoutStatus: json['payoutStatus']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ==================== SYNC RESULT ====================

class StripeSyncResult {
  final bool success;
  final String message;
  final SyncResultDetails results;

  StripeSyncResult({
    required this.success,
    required this.message,
    required this.results,
  });

  factory StripeSyncResult.fromJson(Map<String, dynamic> json) {
    return StripeSyncResult(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      results: SyncResultDetails.fromJson(json['results'] ?? {}),
    );
  }

  int get totalUpdates =>
      results.paymentsUpdated +
      results.refundsRecorded +
      results.transfersUpdated;
}

class SyncResultDetails {
  final int paymentsUpdated;
  final int refundsRecorded;
  final int transfersUpdated;
  final List<String> errors;
  final List<SyncDetail> details;

  SyncResultDetails({
    required this.paymentsUpdated,
    required this.refundsRecorded,
    required this.transfersUpdated,
    required this.errors,
    required this.details,
  });

  factory SyncResultDetails.fromJson(Map<String, dynamic> json) {
    return SyncResultDetails(
      paymentsUpdated: _toInt(json['paymentsUpdated']),
      refundsRecorded: _toInt(json['refundsRecorded']),
      transfersUpdated: _toInt(json['transfersUpdated']),
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => SyncDetail.fromJson(d))
              .toList() ??
          [],
    );
  }
}

class SyncDetail {
  final String type;
  final String reservationId;
  final double amount;
  final String message;

  SyncDetail({
    required this.type,
    required this.reservationId,
    required this.amount,
    required this.message,
  });

  factory SyncDetail.fromJson(Map<String, dynamic> json) {
    return SyncDetail(
      type: json['type']?.toString() ?? '',
      reservationId: json['reservationId']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      message: json['message']?.toString() ?? '',
    );
  }
}
