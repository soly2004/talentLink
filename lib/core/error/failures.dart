/// A user-readable error. Repositories throw these so the presentation layer
/// never has to know about Firebase, geolocator or platform exceptions.
class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Hardware permission was denied, blocked, or the service is switched off.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
