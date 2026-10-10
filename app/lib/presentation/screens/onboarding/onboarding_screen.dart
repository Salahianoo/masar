import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/state/providers.dart';
import 'package:masar/presentation/navigation/router.dart';
import 'package:masar/presentation/themes/app_theme.dart';
import 'package:masar/presentation/components/widgets.dart';

/// The whole sign-up: the student's name. Saving it creates their account and
/// gives them a 5-digit student number; the subject comes later, from home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسمك عشان نعرف نناديك')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final repo = ref.read(masarRepositoryProvider);
      await repo.signIn();
      await repo.updateProfile(name);
      final profile = await repo.currentProfile();
      ref
        ..invalidate(profileProvider)
        ..invalidate(enrollmentsProvider);
      if (!mounted) return;
      final number = profile?.studentId;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(number == null ? 'أهلاً $name!' : 'أهلاً $name! رقمك بمسار $number، بتلاقيه بملفك'),
      ));
      context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Center(child: Icon(Icons.auto_stories_rounded, size: 112, color: AppColors.accent)),
              const SizedBox(height: AppSpacing.lg),
              Text('أهلاً في مسار', style: AppText.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text('خطوة بخطوة لامتحانك، وعلى سرعتك.', style: AppText.label,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              Text('شو اسمك؟', style: AppText.bodyBold),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                maxLength: 40,
                onSubmitted: (_) => _enter(),
                decoration: const InputDecoration(hintText: 'اسمك'),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: 'ادخل', loading: _busy, onPressed: _enter),
              const SizedBox(height: AppSpacing.sm),
              Text('بنعطيك رقم طالب من 5 خانات، بتلاقيه بملفك.', style: AppText.caption,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
