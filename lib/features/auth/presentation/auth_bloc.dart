import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../domain/auth_domain.dart';

// ---------------- Events ----------------
sealed class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class SignInSubmitted extends AuthEvent {
  const SignInSubmitted(this.email, this.password);
  final String email;
  final String password;
}

class SignUpSubmitted extends AuthEvent {
  const SignUpSubmitted(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
}

class BiometricRequested extends AuthEvent {
  const BiometricRequested();
}

class PhotoSelected extends AuthEvent {
  const PhotoSelected(this.bytes);
  final Uint8List bytes;
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

// ---------------- States ----------------
sealed class AuthState {
  const AuthState();
}

/// App just launched, checking for a saved session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Email/password request in flight (login form stays on screen).
class AuthBusy extends AuthState {
  const AuthBusy();
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.error});
  final String? error;
}

/// Returning user: session exists, waiting for fingerprint / face.
class BiometricLocked extends AuthState {
  const BiometricLocked(this.user, {this.error});
  final AppUser user;
  final String? error;
}

class Authenticated extends AuthState {
  const Authenticated(this.user, {this.message, this.messageIsError = false});
  final AppUser user;
  final String? message;
  final bool messageIsError;
}

// ---------------- Bloc ----------------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RestoreSession restoreSession,
    required SignInWithEmail signIn,
    required SignUpWithEmail signUp,
    required BiometricUnlock biometric,
    required UpdateProfilePhoto updatePhoto,
    required SignOut signOut,
  })  : _restoreSession = restoreSession,
        _signIn = signIn,
        _signUp = signUp,
        _biometric = biometric,
        _updatePhoto = updatePhoto,
        _signOut = signOut,
        super(const AuthInitial()) {
    on<AppStarted>(_onStarted);
    on<SignInSubmitted>(_onSignIn);
    on<SignUpSubmitted>(_onSignUp);
    on<BiometricRequested>(_onBiometric);
    on<PhotoSelected>(_onPhoto);
    on<SignOutRequested>(_onSignOut);
  }

  final RestoreSession _restoreSession;
  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final BiometricUnlock _biometric;
  final UpdateProfilePhoto _updatePhoto;
  final SignOut _signOut;

  Future<void> _onStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _restoreSession();
      if (user == null) {
        emit(const Unauthenticated());
        return;
      }
      final canUseBiometrics = await _biometric.isAvailable();
      emit(canUseBiometrics ? BiometricLocked(user) : Authenticated(user));
    } on Failure catch (f) {
      emit(Unauthenticated(error: f.message));
    }
  }

  Future<void> _onSignIn(SignInSubmitted e, Emitter<AuthState> emit) async {
    emit(const AuthBusy());
    try {
      emit(Authenticated(await _signIn(e.email, e.password)));
    } on Failure catch (f) {
      emit(Unauthenticated(error: f.message));
    }
  }

  Future<void> _onSignUp(SignUpSubmitted e, Emitter<AuthState> emit) async {
    emit(const AuthBusy());
    try {
      emit(Authenticated(await _signUp(e.name, e.email, e.password)));
    } on Failure catch (f) {
      emit(Unauthenticated(error: f.message));
    }
  }

  Future<void> _onBiometric(
    BiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! BiometricLocked) return;
    try {
      final ok = await _biometric.authenticate();
      emit(
        ok
            ? Authenticated(current.user)
            : BiometricLocked(
                current.user,
                error: 'Verification was cancelled. Try again or use your password.',
              ),
      );
    } on Failure catch (f) {
      // Permission/hardware problems never crash the app - show a message.
      emit(BiometricLocked(current.user, error: f.message));
    }
  }

  Future<void> _onPhoto(PhotoSelected e, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! Authenticated) return;
    try {
      final updated = await _updatePhoto(e.bytes);
      emit(Authenticated(updated, message: 'Profile photo updated'));
    } on Failure catch (f) {
      emit(Authenticated(current.user, message: f.message, messageIsError: true));
    }
  }

  Future<void> _onSignOut(SignOutRequested e, Emitter<AuthState> emit) async {
    await _signOut();
    emit(const Unauthenticated());
  }
}