import 'package:equatable/equatable.dart';

class PeriodStats extends Equatable {
  final int completed;
  final double earnings;
  final double tips;

  const PeriodStats({
    required this.completed,
    required this.earnings,
    required this.tips,
  });

  double get totalEarnings => earnings + tips;

  @override
  List<Object?> get props => [completed, earnings, tips];
}

class TodayStats extends Equatable {
  final int completed;
  final int inProgress;
  final int assigned;
  final double earnings;
  final double tips;

  const TodayStats({
    required this.completed,
    required this.inProgress,
    required this.assigned,
    required this.earnings,
    required this.tips,
  });

  int get totalActive => inProgress + assigned;
  double get totalEarnings => earnings + tips;

  @override
  List<Object?> get props => [completed, inProgress, assigned, earnings, tips];
}

class AllTimeStats extends Equatable {
  final int completed;
  final double earnings;
  final double tips;
  final double averageRating;
  final int totalRatings;

  const AllTimeStats({
    required this.completed,
    required this.earnings,
    required this.tips,
    required this.averageRating,
    required this.totalRatings,
  });

  double get totalEarnings => earnings + tips;

  @override
  List<Object?> get props =>
      [completed, earnings, tips, averageRating, totalRatings];
}

class WorkerStats extends Equatable {
  final TodayStats today;
  final PeriodStats week;
  final PeriodStats month;
  final AllTimeStats allTime;
  final bool isAvailable;

  const WorkerStats({
    required this.today,
    required this.week,
    required this.month,
    required this.allTime,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [today, week, month, allTime, isAvailable];
}

class DailyEarning extends Equatable {
  final String date;
  final int jobsCount;
  final double earnings;
  final double tips;

  const DailyEarning({
    required this.date,
    required this.jobsCount,
    required this.earnings,
    required this.tips,
  });

  double get total => earnings + tips;

  @override
  List<Object?> get props => [date, jobsCount, earnings, tips];
}

class EarningsSummary extends Equatable {
  final int totalJobs;
  final double totalEarnings;
  final double totalTips;
  final double avgJobPrice;

  const EarningsSummary({
    required this.totalJobs,
    required this.totalEarnings,
    required this.totalTips,
    required this.avgJobPrice,
  });

  double get grandTotal => totalEarnings + totalTips;

  @override
  List<Object?> get props => [totalJobs, totalEarnings, totalTips, avgJobPrice];
}

class EarningsBreakdown extends Equatable {
  final String period;
  final DateTime startDate;
  final List<DailyEarning> daily;
  final EarningsSummary summary;

  const EarningsBreakdown({
    required this.period,
    required this.startDate,
    required this.daily,
    required this.summary,
  });

  @override
  List<Object?> get props => [period, startDate, daily, summary];
}
