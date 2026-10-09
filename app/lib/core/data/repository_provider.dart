import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_masar_repository.dart';
import 'local_masar_repository.dart';
import 'masar_repository.dart';

/// `--dart-define=LOCAL=true` (or the older `MOCK=true`) → the five real demo
/// papers on the device, رفيق on the team PC. Otherwise → Firebase.
const bool kUseLocal = bool.fromEnvironment('LOCAL') || bool.fromEnvironment('MOCK');

/// The only way screens reach data. Never call Firebase directly.
final masarRepositoryProvider = Provider<MasarRepository>((ref) {
  if (kUseLocal) return LocalMasarRepository();
  return FirebaseMasarRepository();
});
