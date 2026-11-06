// DATA LAYER - geolocator + Firestore.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/failures.dart';
import '../../learning/domain/learning_domain.dart';
import '../domain/check_in_domain.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  @override
  Future<CheckInResult> checkIn({
    required String uid,
    required CohortSession session,
  }) async {
    await _ensureLocationAccess();

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const Failure('We could not get a GPS fix. Move outdoors and retry.');
    }

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      session.latitude,
      session.longitude,
    );
    final verified = distance <= session.radiusMeters;

    if (verified) {
      try {
        await _db.collection('checkins').add({
          'uid': uid,
          'sessionId': session.id,
          'sessionTitle': session.title,
          'lat': position.latitude,
          'lng': position.longitude,
          'distanceMeters': distance.round(),
          'checkedInAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException {
        throw const Failure('You are at the venue, but we could not save the check-in.');
      }
    }
    return CheckInResult(verified: verified, distanceMeters: distance);
  }

  /// Handles every permission outcome with a clear message - never a crash.
  Future<void> _ensureLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const PermissionFailure(
        'Location is turned off. Switch it on in your device settings to check in.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const PermissionFailure(
        'We need location access to confirm you are at the event.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PermissionFailure(
        'Location access is blocked. Enable it for TalentLink in Settings, then try again.',
      );
    }
  }
}
