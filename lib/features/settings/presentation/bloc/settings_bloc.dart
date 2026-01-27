import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/get_preferences_usecase.dart';
import '../../domain/usecases/update_preferences_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';

// Events
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdatePushNotifications extends SettingsEvent {
  final bool enabled;
  UpdatePushNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateSound extends SettingsEvent {
  final bool enabled;
  UpdateSound(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateDarkTheme extends SettingsEvent {
  final bool enabled;
  UpdateDarkTheme(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class DeleteAccountRequested extends SettingsEvent {
  final String password;
  DeleteAccountRequested(this.password);

  @override
  List<Object?> get props => [password];
}

class ClearSettingsMessages extends SettingsEvent {}

// States
class SettingsState extends Equatable {
  final UserPreferences preferences;
  final bool isLoading;
  final bool isDeleting;
  final bool isAccountDeleted;
  final String? errorMessage;
  final String? successMessage;

  const SettingsState({
    this.preferences = const UserPreferences(),
    this.isLoading = false,
    this.isDeleting = false,
    this.isAccountDeleted = false,
    this.errorMessage,
    this.successMessage,
  });

  SettingsState copyWith({
    UserPreferences? preferences,
    bool? isLoading,
    bool? isDeleting,
    bool? isAccountDeleted,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      isAccountDeleted: isAccountDeleted ?? this.isAccountDeleted,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        preferences,
        isLoading,
        isDeleting,
        isAccountDeleted,
        errorMessage,
        successMessage,
      ];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetPreferencesUseCase getPreferences;
  final UpdatePreferencesUseCase updatePreferences;
  final DeleteAccountUseCase deleteAccount;

  SettingsBloc({
    required this.getPreferences,
    required this.updatePreferences,
    required this.deleteAccount,
  }) : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdatePushNotifications>(_onUpdatePushNotifications);
    on<UpdateSound>(_onUpdateSound);
    on<UpdateDarkTheme>(_onUpdateDarkTheme);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
    on<ClearSettingsMessages>(_onClearMessages);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await getPreferences();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      (preferences) => emit(state.copyWith(
        isLoading: false,
        preferences: preferences,
      )),
    );
  }

  Future<void> _onUpdatePushNotifications(
    UpdatePushNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    final newPreferences = state.preferences.copyWith(
      pushNotificationsEnabled: event.enabled,
    );

    // Optimistic update
    emit(state.copyWith(preferences: newPreferences, clearMessages: true));

    final result = await updatePreferences(newPreferences);

    result.fold(
      (failure) {
        // Revert on error
        emit(state.copyWith(
          preferences: state.preferences.copyWith(
            pushNotificationsEnabled: !event.enabled,
          ),
          errorMessage: failure.message,
        ));
      },
      (updatedPreferences) => emit(state.copyWith(
        preferences: updatedPreferences,
        successMessage: event.enabled
            ? 'settings_notificationsEnabled'
            : 'settings_notificationsDisabled',
      )),
    );
  }

  Future<void> _onUpdateSound(
    UpdateSound event,
    Emitter<SettingsState> emit,
  ) async {
    final newPreferences = state.preferences.copyWith(
      soundEnabled: event.enabled,
    );

    emit(state.copyWith(preferences: newPreferences, clearMessages: true));

    final result = await updatePreferences(newPreferences);

    result.fold(
      (failure) {
        emit(state.copyWith(
          preferences: state.preferences.copyWith(
            soundEnabled: !event.enabled,
          ),
          errorMessage: failure.message,
        ));
      },
      (updatedPreferences) => emit(state.copyWith(
        preferences: updatedPreferences,
        successMessage: event.enabled
            ? 'settings_soundsEnabled'
            : 'settings_soundsDisabled',
      )),
    );
  }

  Future<void> _onUpdateDarkTheme(
    UpdateDarkTheme event,
    Emitter<SettingsState> emit,
  ) async {
    final newPreferences = state.preferences.copyWith(
      darkThemeEnabled: event.enabled,
    );

    emit(state.copyWith(preferences: newPreferences, clearMessages: true));

    final result = await updatePreferences(newPreferences);

    result.fold(
      (failure) {
        emit(state.copyWith(
          preferences: state.preferences.copyWith(
            darkThemeEnabled: !event.enabled,
          ),
          errorMessage: failure.message,
        ));
      },
      (updatedPreferences) => emit(state.copyWith(
        preferences: updatedPreferences,
        successMessage: event.enabled
            ? 'settings_darkThemeEnabled'
            : 'settings_lightThemeEnabled',
      )),
    );
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isDeleting: true, clearMessages: true));

    final result = await deleteAccount(event.password);

    result.fold(
      (failure) => emit(state.copyWith(
        isDeleting: false,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        isDeleting: false,
        isAccountDeleted: true,
        successMessage: 'settings_accountDeleted',
      )),
    );
  }

  void _onClearMessages(
    ClearSettingsMessages event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }
}
