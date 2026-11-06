// DATA LAYER - REST (mock) + Cloud Firestore.
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../core/error/failures.dart';
import '../domain/learning_domain.dart';

/// JSON -> strictly typed domain object, via a factory constructor.
class SessionModel extends CohortSession {
  const SessionModel({
    required super.id,
    required super.title,
    required super.location,
    required super.startsAt,
    required super.latitude,
    required super.longitude,
    super.radiusMeters,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        location: json['location'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        radiusMeters: (json['radius'] as num?)?.toInt() ?? 150,
      );
}

class SessionsRemoteDataSource {
  SessionsRemoteDataSource(this._client);
  final http.Client _client;

  /// Point this at your mock API (mocki.io, beeceptor, json-server...).
  /// Expected body: { "sessions": [ { id, title, location, startsAt, lat, lng, radius } ] }
  static const String endpoint = 'https://YOUR-MOCK-API.example.com/sessions';

  Future<List<SessionModel>> fetch() async {
    try {
      final res = await _client
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) throw const FormatException('bad status');
      return _parse(res.body);
    } catch (_) {
      // Mock API unreachable -> use bundled sample so the demo never breaks.
      return _parse(jsonEncode({'sessions': _sample()}));
    }
  }

  List<SessionModel> _parse(String body) {
    final list = (jsonDecode(body) as Map<String, dynamic>)['sessions'] as List;
    return list
        .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Map<String, dynamic>> _sample() {
    final now = DateTime.now();
    String inDays(int d, int hour) => DateTime(now.year, now.month, now.day + d, hour)
        .toIso8601String();
    return [
      // TODO: for your demo video, set the first lat/lng to where you are.
      {
        'id': 'cohort-1',
        'title': 'Leadership Kickoff Workshop',
        'location': 'Smart Village, Cairo',
        'startsAt': inDays(2, 10),
        'lat': 30.0714,
        'lng': 31.0171,
        'radius': 200,
      },
      {
        'id': 'cohort-2',
        'title': 'Safety & Compliance Refresher',
        'location': 'Alexandria Logistics Hub',
        'startsAt': inDays(5, 9),
        'lat': 31.2001,
        'lng': 29.9187,
        'radius': 150,
      },
      {
        'id': 'cohort-3',
        'title': 'Data Skills Bootcamp - Day 1',
        'location': 'Cairo HQ, New Cairo',
        'startsAt': inDays(9, 11),
        'lat': 30.0131,
        'lng': 31.4313,
        'radius': 150,
      },
    ];
  }
}

class LearningRepositoryImpl implements LearningRepository {
  LearningRepositoryImpl(this._remote, this._db);
  final SessionsRemoteDataSource _remote;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _progress(String uid) =>
      _db.collection('users').doc(uid).collection('progress');

  @override
  Future<List<CohortSession>> getUpcomingSessions() => _remote.fetch();

  /// Real-time: every change in Firestore flows straight to the UI.
  @override
  Stream<Map<String, int>> watchProgress(String uid) {
    return _progress(uid).snapshots().map((snap) => {
          for (final doc in snap.docs)
            doc.id: (doc.data()['percent'] as num?)?.toInt() ?? 0,
        });
  }

  @override
  Future<void> setProgress(String uid, String moduleId, int percent) async {
    try {
      await _progress(uid).doc(moduleId).set({
        'percent': percent.clamp(0, 100),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      throw const Failure('Could not save your progress. Try again.');
    }
  }
}
