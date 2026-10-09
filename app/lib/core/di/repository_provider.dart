import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masar/data/datasources/local/session_store.dart';
import 'package:masar/data/repositories/firebase_masar_repository.dart';
import 'package:masar/data/repositories/firebase_google_account_service.dart';
import 'package:masar/data/repositories/local_masar_repository.dart';
import 'package:masar/domain/repositories/google_account_service.dart';
import 'package:masar/domain/repositories/masar_repository.dart';

/// `--dart-define=LOCAL=true` (or the older `MOCK=true`) → the five real demo
/// papers on the device, رفيق on the team PC. Otherwise → Firebase.
const bool kUseLocal = bool.fromEnvironment('LOCAL') || bool.fromEnvironment('MOCK');

/// The only way screens reach data. Never call Firebase directly.
final masarRepositoryProvider = Provider<MasarRepository>((ref) {
  if (kUseLocal) return LocalMasarRepository(store: SharedPrefsSessionStore());
  return FirebaseMasarRepository();
});

/// Google login is available only for the Firebase-backed app.
final googleAccountServiceProvider = Provider<GoogleAccountService?>((ref) {
  if (kUseLocal) return null;
  return FirebaseGoogleAccountService();
});
