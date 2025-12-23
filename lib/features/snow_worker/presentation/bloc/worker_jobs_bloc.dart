import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/worker_job.dart';
import '../../domain/usecases/get_available_jobs_usecase.dart';
import '../../domain/usecases/get_my_jobs_usecase.dart';
import '../../domain/usecases/get_job_history_usecase.dart';
import '../../domain/usecases/job_actions_usecase.dart';

// Events
abstract class WorkerJobsEvent extends Equatable {
  const WorkerJobsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAvailableJobs extends WorkerJobsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const LoadAvailableJobs({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

class LoadMyJobs extends WorkerJobsEvent {
  const LoadMyJobs();
}

class RefreshJobs extends WorkerJobsEvent {
  final double? latitude;
  final double? longitude;

  const RefreshJobs({this.latitude, this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class AcceptJob extends WorkerJobsEvent {
  final String jobId;

  const AcceptJob(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class MarkEnRoute extends WorkerJobsEvent {
  final String jobId;
  final double? latitude;
  final double? longitude;
  final int? estimatedMinutes;

  const MarkEnRoute(
    this.jobId, {
    this.latitude,
    this.longitude,
    this.estimatedMinutes,
  });

  @override
  List<Object?> get props => [jobId, latitude, longitude, estimatedMinutes];
}

class StartJob extends WorkerJobsEvent {
  final String jobId;

  const StartJob(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class CompleteJob extends WorkerJobsEvent {
  final String jobId;
  final String? workerNotes;

  const CompleteJob(
    this.jobId, {
    this.workerNotes,
  });

  @override
  List<Object?> get props => [jobId, workerNotes];
}

class SelectActiveJob extends WorkerJobsEvent {
  final WorkerJob? job;

  const SelectActiveJob(this.job);

  @override
  List<Object?> get props => [job];
}

class LoadJobHistory extends WorkerJobsEvent {
  final int page;
  final int limit;

  const LoadJobHistory({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class LoadMoreHistory extends WorkerJobsEvent {
  const LoadMoreHistory();
}

// States
abstract class WorkerJobsState extends Equatable {
  const WorkerJobsState();

  @override
  List<Object?> get props => [];
}

class WorkerJobsInitial extends WorkerJobsState {
  const WorkerJobsInitial();
}

class WorkerJobsLoading extends WorkerJobsState {
  const WorkerJobsLoading();
}

class WorkerJobsLoaded extends WorkerJobsState {
  final List<WorkerJob> availableJobs;
  final List<WorkerJob> myJobs;
  final WorkerJob? activeJob;
  final bool isRefreshing;

  const WorkerJobsLoaded({
    required this.availableJobs,
    required this.myJobs,
    this.activeJob,
    this.isRefreshing = false,
  });

  WorkerJobsLoaded copyWith({
    List<WorkerJob>? availableJobs,
    List<WorkerJob>? myJobs,
    WorkerJob? activeJob,
    bool? isRefreshing,
  }) {
    return WorkerJobsLoaded(
      availableJobs: availableJobs ?? this.availableJobs,
      myJobs: myJobs ?? this.myJobs,
      activeJob: activeJob ?? this.activeJob,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [availableJobs, myJobs, activeJob, isRefreshing];
}

class JobActionLoading extends WorkerJobsState {
  final String jobId;
  final String action;
  final WorkerJobsLoaded previousState;

  const JobActionLoading({
    required this.jobId,
    required this.action,
    required this.previousState,
  });

  @override
  List<Object?> get props => [jobId, action, previousState];
}

class JobActionSuccess extends WorkerJobsState {
  final WorkerJob job;
  final String action;
  final String message;
  final WorkerJob? updatedJob;

  const JobActionSuccess({
    required this.job,
    required this.action,
    required this.message,
    this.updatedJob,
  });

  @override
  List<Object?> get props => [job, action, message, updatedJob];
}

class JobHistoryLoaded extends WorkerJobsState {
  final List<WorkerJob> jobs;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const JobHistoryLoaded({
    required this.jobs,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  JobHistoryLoaded copyWith({
    List<WorkerJob>? jobs,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return JobHistoryLoaded(
      jobs: jobs ?? this.jobs,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [jobs, currentPage, hasMore, isLoadingMore];
}

class WorkerJobsError extends WorkerJobsState {
  final String message;
  final WorkerJobsLoaded? previousState;

  const WorkerJobsError(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}

// BLoC
class WorkerJobsBloc extends Bloc<WorkerJobsEvent, WorkerJobsState> {
  final GetAvailableJobsUseCase getAvailableJobsUseCase;
  final GetMyJobsUseCase getMyJobsUseCase;
  final GetJobHistoryUseCase getJobHistoryUseCase;
  final AcceptJobUseCase acceptJobUseCase;
  final MarkEnRouteUseCase markEnRouteUseCase;
  final StartJobUseCase startJobUseCase;
  final CompleteJobUseCase completeJobUseCase;

  double? _lastLatitude;
  double? _lastLongitude;
  int _historyPage = 1;
  static const int _historyLimit = 20;

  WorkerJobsBloc({
    required this.getAvailableJobsUseCase,
    required this.getMyJobsUseCase,
    required this.getJobHistoryUseCase,
    required this.acceptJobUseCase,
    required this.markEnRouteUseCase,
    required this.startJobUseCase,
    required this.completeJobUseCase,
  }) : super(const WorkerJobsInitial()) {
    on<LoadAvailableJobs>(_onLoadAvailableJobs);
    on<LoadMyJobs>(_onLoadMyJobs);
    on<RefreshJobs>(_onRefreshJobs);
    on<AcceptJob>(_onAcceptJob);
    on<MarkEnRoute>(_onMarkEnRoute);
    on<StartJob>(_onStartJob);
    on<CompleteJob>(_onCompleteJob);
    on<SelectActiveJob>(_onSelectActiveJob);
    on<LoadJobHistory>(_onLoadJobHistory);
    on<LoadMoreHistory>(_onLoadMoreHistory);
  }

  Future<void> _onLoadAvailableJobs(
    LoadAvailableJobs event,
    Emitter<WorkerJobsState> emit,
  ) async {
    emit(const WorkerJobsLoading());

    _lastLatitude = event.latitude;
    _lastLongitude = event.longitude;

    final availableResult = await getAvailableJobsUseCase(
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: event.radiusKm,
    );

    final myJobsResult = await getMyJobsUseCase();

    availableResult.fold(
      (failure) => emit(WorkerJobsError(failure.message)),
      (availableJobs) {
        myJobsResult.fold(
          (failure) => emit(WorkerJobsError(failure.message)),
          (myJobs) {
            // Find active job (in progress)
            final activeJob = myJobs
                .where((j) => j.status == JobStatus.inProgress)
                .firstOrNull;

            emit(WorkerJobsLoaded(
              availableJobs: availableJobs,
              myJobs: myJobs,
              activeJob: activeJob,
            ));
          },
        );
      },
    );
  }

  Future<void> _onLoadMyJobs(
    LoadMyJobs event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorkerJobsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const WorkerJobsLoading());
    }

    final result = await getMyJobsUseCase();

    result.fold(
      (failure) {
        if (currentState is WorkerJobsLoaded) {
          emit(WorkerJobsError(failure.message, previousState: currentState));
        } else {
          emit(WorkerJobsError(failure.message));
        }
      },
      (myJobs) {
        final activeJob =
            myJobs.where((j) => j.status == JobStatus.inProgress).firstOrNull;

        if (currentState is WorkerJobsLoaded) {
          emit(currentState.copyWith(
            myJobs: myJobs,
            activeJob: activeJob,
            isRefreshing: false,
          ));
        } else {
          emit(WorkerJobsLoaded(
            availableJobs: const [],
            myJobs: myJobs,
            activeJob: activeJob,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshJobs(
    RefreshJobs event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final lat = event.latitude ?? _lastLatitude;
    final lng = event.longitude ?? _lastLongitude;

    if (lat == null || lng == null) {
      emit(const WorkerJobsError('Position non disponible'));
      return;
    }

    final currentState = state;
    if (currentState is WorkerJobsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    final availableResult = await getAvailableJobsUseCase(
      latitude: lat,
      longitude: lng,
    );

    final myJobsResult = await getMyJobsUseCase();

    availableResult.fold(
      (failure) {
        if (currentState is WorkerJobsLoaded) {
          emit(currentState.copyWith(isRefreshing: false));
        }
        emit(WorkerJobsError(failure.message));
      },
      (availableJobs) {
        myJobsResult.fold(
          (failure) {
            if (currentState is WorkerJobsLoaded) {
              emit(currentState.copyWith(isRefreshing: false));
            }
            emit(WorkerJobsError(failure.message));
          },
          (myJobs) {
            final activeJob = myJobs
                .where((j) => j.status == JobStatus.inProgress)
                .firstOrNull;

            emit(WorkerJobsLoaded(
              availableJobs: availableJobs,
              myJobs: myJobs,
              activeJob: activeJob,
            ));
          },
        );
      },
    );
  }

  Future<void> _onAcceptJob(
    AcceptJob event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final currentState = state;

    // Get previous loaded state if available, or create empty one
    WorkerJobsLoaded previousLoaded;
    if (currentState is WorkerJobsLoaded) {
      previousLoaded = currentState;
    } else if (currentState is JobActionLoading) {
      previousLoaded = currentState.previousState;
    } else {
      // Create empty state for standalone usage (e.g., from details page)
      previousLoaded = const WorkerJobsLoaded(availableJobs: [], myJobs: []);
    }

    emit(JobActionLoading(
      jobId: event.jobId,
      action: 'accept',
      previousState: previousLoaded,
    ));

    final result = await acceptJobUseCase(event.jobId);

    result.fold(
      (failure) => emit(WorkerJobsError(failure.message, previousState: previousLoaded)),
      (job) {
        // Update lists
        final updatedAvailable = previousLoaded.availableJobs
            .where((j) => j.id != event.jobId)
            .toList();
        final updatedMyJobs = [...previousLoaded.myJobs, job];

        emit(JobActionSuccess(
          job: job,
          action: 'accept',
          message: 'Job accepté avec succès!',
        ));

        emit(WorkerJobsLoaded(
          availableJobs: updatedAvailable,
          myJobs: updatedMyJobs,
          activeJob: previousLoaded.activeJob,
        ));
      },
    );
  }

  Future<void> _onMarkEnRoute(
    MarkEnRoute event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final currentState = state;
    final previousLoaded = currentState is WorkerJobsLoaded ? currentState : null;

    emit(JobActionLoading(
      jobId: event.jobId,
      action: 'en-route',
      previousState: previousLoaded ?? const WorkerJobsLoaded(availableJobs: [], myJobs: []),
    ));

    final result = await markEnRouteUseCase(
      jobId: event.jobId,
      latitude: event.latitude,
      longitude: event.longitude,
      estimatedMinutes: event.estimatedMinutes,
    );

    result.fold(
      (failure) => emit(WorkerJobsError(failure.message, previousState: previousLoaded)),
      (job) {
        emit(JobActionSuccess(
          job: job,
          action: 'en-route',
          message: 'En route vers le client!',
          updatedJob: job,
        ));

        if (previousLoaded != null) {
          final updatedMyJobs = previousLoaded.myJobs
              .map((j) => j.id == event.jobId ? job : j)
              .toList();
          emit(previousLoaded.copyWith(myJobs: updatedMyJobs));
        } else {
          emit(WorkerJobsLoaded(availableJobs: const [], myJobs: [job]));
        }
      },
    );
  }

  Future<void> _onStartJob(
    StartJob event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final currentState = state;
    final previousLoaded = currentState is WorkerJobsLoaded ? currentState : null;

    emit(JobActionLoading(
      jobId: event.jobId,
      action: 'start',
      previousState: previousLoaded ?? const WorkerJobsLoaded(availableJobs: [], myJobs: []),
    ));

    final result = await startJobUseCase(event.jobId);

    result.fold(
      (failure) => emit(WorkerJobsError(failure.message, previousState: previousLoaded)),
      (job) {
        emit(JobActionSuccess(
          job: job,
          action: 'start',
          message: 'Travail commencé!',
          updatedJob: job,
        ));

        if (previousLoaded != null) {
          final updatedMyJobs = previousLoaded.myJobs
              .map((j) => j.id == event.jobId ? job : j)
              .toList();
          emit(previousLoaded.copyWith(myJobs: updatedMyJobs, activeJob: job));
        } else {
          emit(WorkerJobsLoaded(availableJobs: const [], myJobs: [job], activeJob: job));
        }
      },
    );
  }

  Future<void> _onCompleteJob(
    CompleteJob event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final currentState = state;
    final previousLoaded = currentState is WorkerJobsLoaded ? currentState : null;

    emit(JobActionLoading(
      jobId: event.jobId,
      action: 'complete',
      previousState: previousLoaded ?? const WorkerJobsLoaded(availableJobs: [], myJobs: []),
    ));

    final result = await completeJobUseCase(
      jobId: event.jobId,
      workerNotes: event.workerNotes,
    );

    result.fold(
      (failure) => emit(WorkerJobsError(failure.message, previousState: previousLoaded)),
      (job) {
        emit(JobActionSuccess(
          job: job,
          action: 'complete',
          message: 'Travail terminé avec succès!',
        ));

        if (previousLoaded != null) {
          final updatedMyJobs = previousLoaded.myJobs
              .where((j) => j.id != event.jobId)
              .toList();
          emit(previousLoaded.copyWith(myJobs: updatedMyJobs, activeJob: null));
        } else {
          emit(const WorkerJobsLoaded(availableJobs: [], myJobs: []));
        }
      },
    );
  }

  void _onSelectActiveJob(
    SelectActiveJob event,
    Emitter<WorkerJobsState> emit,
  ) {
    final currentState = state;
    if (currentState is WorkerJobsLoaded) {
      emit(currentState.copyWith(activeJob: event.job));
    }
  }

  Future<void> _onLoadJobHistory(
    LoadJobHistory event,
    Emitter<WorkerJobsState> emit,
  ) async {
    emit(const WorkerJobsLoading());
    _historyPage = event.page;

    final result = await getJobHistoryUseCase(
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(WorkerJobsError(failure.message)),
      (jobs) => emit(JobHistoryLoaded(
        jobs: jobs,
        currentPage: event.page,
        hasMore: jobs.length >= event.limit,
      )),
    );
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreHistory event,
    Emitter<WorkerJobsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JobHistoryLoaded || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _historyPage++;

    final result = await getJobHistoryUseCase(
      page: _historyPage,
      limit: _historyLimit,
    );

    result.fold(
      (failure) {
        _historyPage--;
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newJobs) => emit(JobHistoryLoaded(
        jobs: [...currentState.jobs, ...newJobs],
        currentPage: _historyPage,
        hasMore: newJobs.length >= _historyLimit,
      )),
    );
  }
}
