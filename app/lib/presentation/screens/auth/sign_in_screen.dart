import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/navigation/routes.dart';
import 'package:masar/presentation/screens/splash/splash_screen.dart';
import 'package:masar/presentation/state/providers.dart';
import 'package:masar/presentation/themes/app_theme.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;

  Future<void> _signIn() async {
    final google = ref.read(googleAccountServiceProvider);
    if (google == null || _busy) return;
    setState(() => _busy = true);
    try {
      final name = await google.signInWithGoogle();
      if (name == null || !mounted) return;
      ref.invalidate(startRouteProvider);
      if (mounted) context.go(AppRoutes.splash);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: MentorAvatar(pose: MentorPose.wave, size: 120)),
                const SizedBox(height: AppSpacing.xl),
                Text('أهلاً في مسار', style: AppText.title, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text('سجّل بحساب Google عشان تحفظ تقدّمك وترجعله بأي وقت.',
                    style: AppText.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label: 'المتابعة باستخدام Google',
                  icon: Icons.account_circle_outlined,
                  loading: _busy,
                  onPressed: _signIn,
                ),
              ],
            ),
          ),
        ),
      );
}
