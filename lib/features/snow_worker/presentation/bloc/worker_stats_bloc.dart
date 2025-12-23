import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/worker_stats.dart';
import '../../domain/usecases/get_worker_stats_usecase.dart';

// Events
abstract class WorkerStatsEvent extends Equatable {
  const WorkerStatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStats extends WorkerStatsEvent {
  const LoadStats();
}

class LoadEarnings extends WorkerStatsEvent {
  final String period;

  const LoadEarnings({this.period = 'week'});

  @override
  List<Object?> get props => [period];
}

class RefreshStats extends WorkerStatsEvent {
  const RefreshStats();
}

// States
abstract class WorkerStatsState extends Equatable {
  const WorkerStatsState();

  @override
  List<Object?> get props => [];
}

class WorkerStatsInitial extends WorkerStatsState {
  const WorkerStatsInitial();
}

class WorkerStatsLoading extends WorkerStatsState {
  const WorkerStatsLoading();
}

class WorkerStatsLoaded extends WorkerStatsState {
  final WorkerStats stats;
  final EarningsBreakdown? earnings;
  final bool isRefreshing;

  const WorkerStatsLoaded({
    required this.stats,
    this.earnings,
    this.isRefreshing = false,
  });

  WorkerStatsLoaded copyWith({
    WorkerStats? stats,
    EarningsBreakdown? earnings,
    bool? isRefreshing,
  }) {
    return WorkerStatsLoaded(
      stats: stats ?? this.stats,
      earnings: earnings ?? this.earnings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [stats, earnings, isRefreshing];
}

class WorkerStatsError extends WorkerStatsState {
  final String message;

  const WorkerStatsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class WorkerStatsBloc extends Bloc<WorkerStatsEvent, WorkerStatsState> {
  final GetWorkerStatsUseCase getWorkerStatsUseCase;
  final GetEarningsUseCase getEarningsUseCase;

  WorkerStatsBloc({
    required this.getWorkerStatsUseCase,
    required this.getEarningsUseCase,
  }) : super(const WorkerStatsInitial()) {
    on<LoadStats>(_onLoadStats);
    on<LoadEarnings>(_onLoadEarnings);
    on<RefreshStats>(_onRefreshStats);
  }

  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<WorkerStatsState> emit,
  ) async {
    emit(const WorkerStatsLoading());

    final result = await getWorkerStatsUseCase();

    result.fold(
      (failure) => emit(WorkerStatsError(failure.message)),
      (stats) => emit(WorkerStatsLoaded(stats: stats)),
    );
  }

  Future<void> _onLoadEarnings(
    LoadEarnings event,
    Emitter<WorkerStatsState> emit,
  ) async {
    final currentState = state;

    if (currentState is WorkerStatsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const WorkerStatsLoading());
    }

    final earningsResult = await getEarningsUseCase(period: event.period);

    earningsResult.fold(
      (failure) => emit(WorkerStatsError(failure.message)),
      (earnings) {
        if (currentState is WorkerStatsLoaded) {
          emit(currentState.copyWith(
            earnings: earnings,
            isRefreshing: false,
          ));
        } else {
          // Load stats first if not loaded
          add(const LoadStats());
        }
      },
    );
  }

  Future<void> _onRefreshStats(
    RefreshStats event,
    Emitter<WorkerStatsState> emit,
  ) async {
    final currentState = state;

    if (currentState is WorkerStatsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    final result = await getWorkerStatsUseCase();

    result.fold(
      (failure) {
        if (currentState is WorkerStatsLoaded) {
          emit(currentState.copyWith(isRefreshing: false));
        }
        emit(WorkerStatsError(failure.message));
      },
      (stats) {
        if (currentState is WorkerStatsLoaded) {
          emit(currentState.copyWith(
            stats: stats,
            isRefreshing: false,
          ));
        } else {
          emit(WorkerStatsLoaded(stats: stats));
        }
      },
    );
  }
}
