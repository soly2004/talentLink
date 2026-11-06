// DOMAIN LAYER - pure Dart.
import '../../learning/domain/learning_domain.dart';

class CheckInResult {
  const CheckInResult({required this.verified, required this.distanceMeters});
  final bool verified;
  final double distanceMeters;
}

abstract class CheckInRepository {
  /// Reads the device GPS, compares it to the event and, if close enough,
  /// records the attendance. Throws a Failure when something goes wrong.
  Future<CheckInResult> checkIn({
    required String uid,
    required CohortSession session,
  });
}

class CheckInToSession {
  CheckInToSession(this._repo);
  final CheckInRepository _repo;
  Future<CheckInResult> call(String uid, CohortSession session) =>
      _repo.checkIn(uid: uid, session: session);
}
