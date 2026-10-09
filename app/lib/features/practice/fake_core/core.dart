// TEMPORARY barrel: Osama's features import core ONLY through this file.
// When Amer's core lands, replace these exports with his core/models, core/data,
// core/theme and core/widgets, and delete the rest of fake_core/.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_masar_repository.dart';
import 'masar_repository.dart';

export 'masar_repository.dart';
export 'models.dart';
export 'theme.dart';
export 'widgets.dart';

final masarRepositoryProvider = Provider<MasarRepository>((ref) => FakeMasarRepository());
