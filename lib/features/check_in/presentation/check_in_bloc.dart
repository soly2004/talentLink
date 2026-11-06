import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../learning/domain/learning_domain.dart';
import '../domain/check_in_domain.dart';

sealed class CheckInEvent {
  const CheckInEvent();
}

class SessionChosen extends CheckInEvent {
  const SessionChosen(this.sessionId);
  final String sessionId;
}

class CheckInPressed extends CheckInEvent {
  const CheckInPressed(this.uid, this.session);
  final String uid;
  final CohortSession session;
}

enum CheckInStatus { idle, busy, success, tooFar, error }

class CheckInState {
  const CheckInState({
    this.selectedId,
    this.status = CheckInStatus.idle,
    this.message,
  });

  final String? selectedId;
  final CheckInStatus status;
  final String? message;
}

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc(this._checkIn) : super(const CheckInState()) {
    on<SessionChosen>(
      (e, emit) => emit(CheckInState(selectedId: e.sessionId)),
    );
    on<CheckInPressed>(_onPressed);
  }

  final CheckInToSession _checkIn;

  Future<void> _onPressed(
    CheckInPressed event,
    Emitter<CheckInState> emit,
  ) async {
    final id = event.session.id;
    emit(CheckInState(selectedId: id, status: CheckInStatus.busy));
    try {
      final result = await _checkIn(event.uid, event.session);
      final meters = result.distanceMeters.round();
      if (result.verified) {
        emit(CheckInState(
          selectedId: id,
          status: CheckInStatus.success,
          message: "You're checked in! You are $meters m from the venue.",
        ));
      } else {
        emit(CheckInState(
          selectedId: id,
          status: CheckInStatus.tooFar,
          message:
              'You are $meters m away. Get within ${event.session.radiusMeters} m of the venue to check in.',
        ));
      }
    } on Failure catch (f) {
      emit(CheckInState(
        selectedId: id,
        status: CheckInStatus.error,
        message: f.message,
      ));
    }
  }
}
