import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'masar_repository.dart';
import 'mock_masar_repository.dart';
import 'unimplemented_masar_repository.dart';

/// `flutter run --dart-define=MOCK=true` → in-memory mock.
const bool kUseMock = bool.fromEnvironment('MOCK');

/// The only way screens reach data. Never call Firebase directly.
final masarRepositoryProvider = Provider<MasarRepository>((ref) {
  if (kUseMock) return MockMasarRepository();
  return UnimplementedMasarRepository();
});
