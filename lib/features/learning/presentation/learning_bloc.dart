import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../domain/learning_domain.dart';

// ---------------- Events ----------------
sealed class LearningEvent {
  const LearningEvent();
}

class LearningStarted extends LearningEvent {
  const LearningStarted(this.uid);
  final String uid;
}

class ProgressBumped extends LearningEvent {
  const ProgressBumped(this.moduleId);
  final String moduleId;
}

// ---------------- State ----------------
class LearningState {
  const LearningState({
    this.uid,
    this.loading = false,
    this.sessions = const [],
    this.progress = const {},
    this.error,
  });

  final String? uid;
  final bool loading;
  final List<CohortSession> sessions;
  final Map<String, int> progress;
  final String? error;

  LearningState copyWith({
    String? uid,
    bool? loading,
    List<CohortSession>? sessions,
    Map<String, int>? progress,
    String? error,
    bool clearError = false,
  }) {
    return LearningState(
      uid: uid ?? this.uid,
      loading: loading ?? this.loading,
      sessions: sessions ?? this.sessions,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------- Bloc ----------------
class LearningBloc extends Bloc<LearningEvent, LearningState> {
  LearningBloc({
    required GetUpcomingSessions getSessions,
    required WatchProgress watchProgress,
    required UpdateProgress updateProgress,
  })  : _getSessions = getSessions,
        _watchProgress = watchProgress,
        _updateProgress = updateProgress,
        super(const LearningState()) {
    on<LearningStarted>(_onStarted);
    on<ProgressBumped>(_onBumped);
  }

  final GetUpcomingSessions _getSessions;
  final WatchProgress _watchProgress;
  final UpdateProgress _updateProgress;

  Future<void> _onStarted(
    LearningStarted event,
    Emitter<LearningState> emit,
  ) async {
    emit(state.copyWith(uid: event.uid, loading: true, clearError: true));
    try {
      final sessions = await _getSessions();
      emit(state.copyWith(sessions: sessions, loading: false));
    } on Failure catch (f) {
      emit(state.copyWith(loading: false, error: f.message));
    }

    // Stay subscribed: Firestore pushes progress changes in real time.
    await emit.forEach<Map<String, int>>(
      _watchProgress(event.uid),
      onData: (progress) => state.copyWith(progress: progress),
      onError: (_, __) =>
          state.copyWith(error: 'Live sync paused. Check your connection.'),
    );
  }

  Future<void> _onBumped(
    ProgressBumped event,
    Emitter<LearningState> emit,
  ) async {
    final uid = state.uid;
    if (uid == null) return;
    final current = state.progress[event.moduleId] ?? 0;
    final next = (current + 25).clamp(0, 100).toInt();
    try {
      await _updateProgress(uid, event.moduleId, next);
    } on Failure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }
}