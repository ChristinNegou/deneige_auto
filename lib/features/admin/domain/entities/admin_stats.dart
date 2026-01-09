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

class AdminStats {
  final UserStats users;
  final ReservationStats reservations;
  final RevenueStats revenue;
  final List<TopWorker> topWorkers;
  final SupportStats support;

  AdminStats({
    required this.users,
    required this.reservations,
    required this.revenue,
    required this.topWorkers,
    required this.support,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      users: UserStats.fromJson(json['users'] ?? {}),
      reservations: ReservationStats.fromJson(json['reservations'] ?? {}),
      revenue: RevenueStats.fromJson(json['revenue'] ?? {}),
      topWorkers: (json['topWorkers'] as List<dynamic>?)
              ?.map((w) => TopWorker.fromJson(w))
              .toList() ??
          [],
      support: SupportStats.fromJson(json['support'] ?? {}),
    );
  }
}

class UserStats {
  final int total;
  final int clients;
  final int workers;
  final int activeWorkers;

  UserStats({
    required this.total,
    required this.clients,
    required this.workers,
    required this.activeWorkers,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: _toInt(json['total']),
      clients: _toInt(json['clients']),
      workers: _toInt(json['workers']),
      activeWorkers: _toInt(json['activeWorkers']),
    );
  }
}

class ReservationStats {
  final int total;
  final int completed;
  final int cancelled;
  final int pending;
  final int today;
  final int thisMonth;
  final double completionRate;

  ReservationStats({
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.pending,
    required this.today,
    required this.thisMonth,
    required this.completionRate,
  });

  factory ReservationStats.fromJson(Map<String, dynamic> json) {
    return ReservationStats(
      total: _toInt(json['total']),
      completed: _toInt(json['completed']),
      cancelled: _toInt(json['cancelled']),
      pending: _toInt(json['pending']),
      today: _toInt(json['today']),
      thisMonth: _toInt(json['thisMonth']),
      completionRate: _toDouble(json['completionRate']),
    );
  }
}

class RevenueStats {
  final double total;
  final double platformFees;
  final double workerPayouts;
  final double tips;
  final double thisMonth;
  final double monthlyPlatformFees;

  RevenueStats({
    required this.total,
    required this.platformFees,
    required this.workerPayouts,
    required this.tips,
    required this.thisMonth,
    required this.monthlyPlatformFees,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      total: _toDouble(json['total']),
      platformFees: _toDouble(json['platformFees']),
      workerPayouts: _toDouble(json['workerPayouts']),
      tips: _toDouble(json['tips']),
      thisMonth: _toDouble(json['thisMonth']),
      monthlyPlatformFees: _toDouble(json['monthlyPlatformFees']),
    );
  }
}

class TopWorker {
  final String id;
  final String name;
  final int jobsCompleted;
  final double totalEarnings;
  final double rating;

  TopWorker({
    required this.id,
    required this.name,
    required this.jobsCompleted,
    required this.totalEarnings,
    required this.rating,
  });

  factory TopWorker.fromJson(Map<String, dynamic> json) {
    return TopWorker(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      jobsCompleted: _toInt(json['jobsCompleted']),
      totalEarnings: _toDouble(json['totalEarnings']),
      rating: _toDouble(json['rating']),
    );
  }
}

class SupportStats {
  final int total;
  final int pending;
  final int inProgress;
  final int resolved;
  final int closed;
  final int todayNew;
  final double avgResponseTimeHours;

  SupportStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.resolved,
    required this.closed,
    required this.todayNew,
    required this.avgResponseTimeHours,
  });

  factory SupportStats.fromJson(Map<String, dynamic> json) {
    return SupportStats(
      total: _toInt(json['total']),
      pending: _toInt(json['pending']),
      inProgress: _toInt(json['inProgress']),
      resolved: _toInt(json['resolved']),
      closed: _toInt(json['closed']),
      todayNew: _toInt(json['todayNew']),
      avgResponseTimeHours: _toDouble(json['avgResponseTimeHours']),
    );
  }
}
