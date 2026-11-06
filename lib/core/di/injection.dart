import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_domain.dart';
import '../../features/auth/presentation/auth_bloc.dart';
import '../../features/check_in/data/check_in_repository_impl.dart';
import '../../features/check_in/domain/check_in_domain.dart';
import '../../features/check_in/presentation/check_in_bloc.dart';
import '../../features/learning/data/learning_data.dart';
import '../../features/learning/domain/learning_domain.dart';
import '../../features/learning/presentation/learning_bloc.dart';
import '../utils/photo_service.dart';

/// Service locator. Rule of thumb: widgets and BLoCs only ever see
/// abstractions (repositories / use cases); concrete classes are wired here.
final GetIt sl = GetIt.instance;

void configureDependencies() {
  // External
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<PhotoService>(() => PhotoService(ImagePicker()));

  // Data sources + repositories (bound to their domain abstractions)
  sl.registerLazySingleton<SessionsRemoteDataSource>(
    () => SessionsRemoteDataSource(sl<http.Client>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<FirebaseAuth>(),
      sl<FirebaseFirestore>(),
      sl<LocalAuthentication>(),
    ),
  );
  sl.registerLazySingleton<LearningRepository>(
    () => LearningRepositoryImpl(
      sl<SessionsRemoteDataSource>(),
      sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<CheckInRepository>(
    () => CheckInRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // Use cases
  sl.registerLazySingleton(() => RestoreSession(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton(() => BiometricUnlock(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateProfilePhoto(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetUpcomingSessions(sl<LearningRepository>()));
  sl.registerLazySingleton(() => WatchProgress(sl<LearningRepository>()));
  sl.registerLazySingleton(() => UpdateProgress(sl<LearningRepository>()));
  sl.registerLazySingleton(() => CheckInToSession(sl<CheckInRepository>()));

  // BLoCs (a fresh instance each time they are requested)
  sl.registerFactory(
    () => AuthBloc(
      restoreSession: sl(),
      signIn: sl(),
      signUp: sl(),
      biometric: sl(),
      updatePhoto: sl(),
      signOut: sl(),
    ),
  );
  sl.registerFactory(
    () => LearningBloc(
      getSessions: sl(),
      watchProgress: sl(),
      updateProgress: sl(),
    ),
  );
  sl.registerFactory(() => CheckInBloc(sl()));
}
