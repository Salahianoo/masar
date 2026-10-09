import 'masar_repository.dart';

/// Stand-in until Salah's `firebase_masar_repository.dart` lands.
/// Every call throws, so run with `--dart-define=MOCK=true` for now.
// TODO(amer): delete this file and use FirebaseMasarRepository in repository_provider.dart.
class UnimplementedMasarRepository implements MasarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        'FirebaseMasarRepository is not in yet. Run with --dart-define=MOCK=true.',
      );
}
