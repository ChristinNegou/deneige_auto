import '../../domain/entities/worker_stats.dart';

class TodayStatsModel extends TodayStats {
  const TodayStatsModel({
    required super.completed,
    required super.inProgress,
    required super.assigned,
    required super.earnings,
    required super.tips,
  });

  factory TodayStatsModel.fromJson(Map<String, dynamic> json) {
    return TodayStatsModel(
      completed: json['completed'] as int? ?? 0,
      inProgress: json['inProgress'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PeriodStatsModel extends PeriodStats {
  const PeriodStatsModel({
    required super.completed,
    required super.earnings,
    required super.tips,
  });

  factory PeriodStatsModel.fromJson(Map<String, dynamic> json) {
    return PeriodStatsModel(
      completed: json['completed'] as int? ?? 0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AllTimeStatsModel extends AllTimeStats {
  const AllTimeStatsModel({
    required super.completed,
    required super.earnings,
    required super.tips,
    required super.averageRating,
    required super.totalRatings,
  });

  factory AllTimeStatsModel.fromJson(Map<String, dynamic> json) {
    return AllTimeStatsModel(
      completed: json['completed'] as int? ?? 0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalRatings: json['totalRatings'] as int? ?? 0,
    );
  }
}

class WorkerStatsModel extends WorkerStats {
  const WorkerStatsModel({
    required super.today,
    required super.week,
    required super.month,
    required super.allTime,
    required super.isAvailable,
  });

  factory WorkerStatsModel.fromJson(Map<String, dynamic> json) {
    return WorkerStatsModel(
      today: TodayStatsModel.fromJson(json['today'] as Map<String, dynamic>? ?? {}),
      week: PeriodStatsModel.fromJson(json['week'] as Map<String, dynamic>? ?? {}),
      month: PeriodStatsModel.fromJson(json['month'] as Map<String, dynamic>? ?? {}),
      allTime: AllTimeStatsModel.fromJson(json['allTime'] as Map<String, dynamic>? ?? {}),
      isAvailable: json['isAvailable'] as bool? ?? false,
    );
  }
}

class DailyEarningModel extends DailyEarning {
  const DailyEarningModel({
    required super.date,
    required super.jobsCount,
    required super.earnings,
    required super.tips,
  });

  factory DailyEarningModel.fromJson(Map<String, dynamic> json) {
    return DailyEarningModel(
      date: json['_id'] as String? ?? '',
      jobsCount: json['jobsCount'] as int? ?? 0,
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EarningsSummaryModel extends EarningsSummary {
  const EarningsSummaryModel({
    required super.totalJobs,
    required super.totalEarnings,
    required super.totalTips,
    required super.avgJobPrice,
  });

  factory EarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    return EarningsSummaryModel(
      totalJobs: json['totalJobs'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      totalTips: (json['totalTips'] as num?)?.toDouble() ?? 0,
      avgJobPrice: (json['avgJobPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EarningsBreakdownModel extends EarningsBreakdown {
  const EarningsBreakdownModel({
    required super.period,
    required super.startDate,
    required super.daily,
    required super.summary,
  });

  factory EarningsBreakdownModel.fromJson(Map<String, dynamic> json) {
    final dailyJson = json['daily'] as List<dynamic>? ?? [];
    final daily = dailyJson
        .map((d) => DailyEarningModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return EarningsBreakdownModel(
      period: json['period'] as String? ?? 'week',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      daily: daily,
      summary: EarningsSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}
