// DOMAIN LAYER - pure Dart. No Flutter, Firebase or plugin imports allowed.
import 'dart:typed_data';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.photoBase64,
  });

  final String uid;
  final String email;
  final String name;
  final String? photoBase64;
}

abstract class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> signUp(String name, String email, String password);
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometrics();
  Future<AppUser> updatePhoto(Uint8List bytes);
  Future<void> signOut();
}

// ---- Use cases: one job each, depend only on the abstraction above. ----

class RestoreSession {
  RestoreSession(this._repo);
  final AuthRepository _repo;
  Future<AppUser?> call() => _repo.restoreSession();
}

class SignInWithEmail {
  SignInWithEmail(this._repo);
  final AuthRepository _repo;
  Future<AppUser> call(String email, String password) =>
      _repo.signIn(email, password);
}

class SignUpWithEmail {
  SignUpWithEmail(this._repo);
  final AuthRepository _repo;
  Future<AppUser> call(String name, String email, String password) =>
      _repo.signUp(name, email, password);
}

class BiometricUnlock {
  BiometricUnlock(this._repo);
  final AuthRepository _repo;
  Future<bool> isAvailable() => _repo.isBiometricAvailable();
  Future<bool> authenticate() => _repo.authenticateWithBiometrics();
}

class UpdateProfilePhoto {
  UpdateProfilePhoto(this._repo);
  final AuthRepository _repo;
  Future<AppUser> call(Uint8List bytes) => _repo.updatePhoto(bytes);
}

class SignOut {
  SignOut(this._repo);
  final AuthRepository _repo;
  Future<void> call() => _repo.signOut();
}
