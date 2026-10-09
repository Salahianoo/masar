import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:masar/core/di/repository_provider.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/state/theme_mode_provider.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kUseLocal) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (const bool.fromEnvironment('FIREBASE_EMULATORS')) {
      const host = '127.0.0.1';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instanceFor(region: 'europe-west1')
          .useFunctionsEmulator(host, 5001);
    }
  }
  runApp(const ProviderScope(child: MasarApp()));
}

class MasarApp extends ConsumerWidget {
  const MasarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'مسار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // AppColors switches palette at once; a cross-fade would mix the two.
      themeAnimationDuration: Duration.zero,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _PaletteSync(child: child!),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Points [AppColors] at the light or dark palette. Widgets read AppColors
/// directly (not through Theme.of), so on a switch every open screen is
/// rebuilt once, keeping its state.
class _PaletteSync extends StatelessWidget {
  const _PaletteSync({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppColors.use(Theme.of(context).brightness)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        void rebuild(Element e) {
          e.markNeedsBuild();
          e.visitChildren(rebuild);
        }
        if (context.mounted) (context as Element).visitChildren(rebuild);
      });
    }
    return child;
  }
}
