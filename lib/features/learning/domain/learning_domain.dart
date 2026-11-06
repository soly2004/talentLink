// DOMAIN LAYER - pure Dart.

/// An in-person cohort event employees must attend.
class CohortSession {
  const CohortSession({
    required this.id,
    required this.title,
    required this.location,
    required this.startsAt,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150,
  });

  final String id;
  final String title;
  final String location;
  final DateTime startsAt;
  final double latitude;
  final double longitude;

  /// How close (in metres) someone must be for a check-in to count.
  final int radiusMeters;
}

abstract final class ModuleIds {
  static const fundamentals = 'flutter-fundamentals';
  static const data = 'data-state';
  static const firebase = 'firebase-device';
  static const patterns = 'design-patterns';
}

abstract class LearningRepository {
  Future<List<CohortSession>> getUpcomingSessions();
  Stream<Map<String, int>> watchProgress(String uid);
  Future<void> setProgress(String uid, String moduleId, int percent);
}

class GetUpcomingSessions {
  GetUpcomingSessions(this._repo);
  final LearningRepository _repo;
  Future<List<CohortSession>> call() => _repo.getUpcomingSessions();
}

class WatchProgress {
  WatchProgress(this._repo);
  final LearningRepository _repo;
  Stream<Map<String, int>> call(String uid) => _repo.watchProgress(uid);
}

class UpdateProgress {
  UpdateProgress(this._repo);
  final LearningRepository _repo;
  Future<void> call(String uid, String moduleId, int percent) =>
      _repo.setProgress(uid, moduleId, percent);
}
