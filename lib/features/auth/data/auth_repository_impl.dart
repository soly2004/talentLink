// DATA LAYER - the only place that knows about Firebase and local_auth.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/error/failures.dart';
import '../domain/auth_domain.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._db, this._localAuth);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final LocalAuthentication _localAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Future<AppUser?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _load(user);
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _load(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw Failure(_authMessage(e.code));
    }
  }

  @override
  Future<AppUser> signUp(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name);
      await _users.doc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return AppUser(uid: user.uid, email: email, name: name);
    } on FirebaseAuthException catch (e) {
      throw Failure(_authMessage(e.code));
    } on FirebaseException {
      throw const Failure('Account created, but we could not save your profile.');
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirm it\'s you to open TalentLink',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      throw PermissionFailure(_biometricMessage(e.code));
    }
  }

  @override
  Future<AppUser> updatePhoto(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) throw const Failure('Please sign in again.');
    try {
      await _users.doc(user.uid).set(
        {'photoBase64': base64Encode(bytes)},
        SetOptions(merge: true),
      );
    } on FirebaseException {
      throw const Failure('Could not upload your photo. Check your connection.');
    }
    return _load(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  // ---- helpers ----

  Future<AppUser> _load(User user) async {
    try {
      final data = (await _users.doc(user.uid).get()).data() ?? {};
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: (data['name'] as String?) ?? user.displayName ?? 'Learner',
        photoBase64: data['photoBase64'] as String?,
      );
    } on FirebaseException {
      // Offline or rules issue: still let the person in with auth data.
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'Learner',
      );
    }
  }

  String _authMessage(String code) => switch (code) {
        'invalid-email' => "That email address doesn't look right.",
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email or password is incorrect.',
        'user-disabled' => 'This account has been disabled. Contact support.',
        'too-many-requests' => 'Too many attempts. Please wait a moment.',
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        'email-already-in-use' => 'An account with this email already exists.',
        'weak-password' => 'Choose a stronger password (6+ characters).',
        _ => 'Something went wrong. Please try again.',
      };

  String _biometricMessage(String code) => switch (code) {
        'NotAvailable' => 'Biometrics are not available on this device.',
        'NotEnrolled' =>
          'No fingerprint or face is set up. Add one in your device settings.',
        'LockedOut' => 'Too many attempts. Try again in a moment.',
        'PermanentlyLockedOut' =>
          'Biometrics are locked. Unlock your device with your PIN first.',
        _ => 'Biometric check failed. Please try again.',
      };
}
