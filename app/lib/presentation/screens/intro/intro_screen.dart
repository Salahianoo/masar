import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:masar/presentation/components/widgets.dart';
import 'package:masar/presentation/navigation/routes.dart';
import 'package:masar/presentation/state/intro_seen.dart';
import 'package:masar/presentation/themes/app_theme.dart';

/// Three slides on what Masar does, shown once per device before the name.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(Icons.query_stats_rounded, 'اعرف وين واقف',
      '8 أسئلة قصيرة من امتحانات سابقة حقيقية، وبتطلعلك خريطة بكل مفهوم بالمادة ونسبة جاهزيتك للامتحان.'),
  _Slide(Icons.route_rounded, 'خطة يومية على قدّ وقتك',
      'كل يوم بنختارلك أسئلة على المفاهيم الضعيفة عندك، وبنقدّم اللي بيتكرر أكثر بالامتحانات.'),
  _Slide(Icons.auto_stories_rounded, 'امتحانات السنوات بين إيديك',
      'بتقدر ترجع لأسئلة امتحانات حقيقية من بنك خزنة، وتتمرّن على المفاهيم اللي بتحتاجها.'),
];

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await IntroSeen.markSeen();
    if (mounted) context.go(AppRoutes.onboarding);
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(onPressed: last ? null : _finish, child: const Text('تخطّي')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: PrimaryButton(label: last ? 'يلا نبلّش' : 'التالي', onPressed: _next),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(slide.icon, size: 120, color: AppColors.accent),
          const SizedBox(height: AppSpacing.xxl),
          Text(slide.title, style: AppText.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(slide.body, style: AppText.body.copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
