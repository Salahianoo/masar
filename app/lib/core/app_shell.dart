import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'widgets/mentor_avatar.dart';

/// Bottom navigation with the 4 tabs: مساري · خزنة · {mentorName} · أنا.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentorName = ref.watch(configProvider).value?.mentorName ?? '';
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) =>
              navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.route_outlined), label: 'مساري'),
            const NavigationDestination(icon: Icon(Icons.auto_stories_outlined), label: 'خزنة'),
            NavigationDestination(
              icon: const Opacity(opacity: .75, child: MentorBadge(size: 30)),
              selectedIcon: const MentorBadge(size: 30, ring: true),
              label: mentorName,
            ),
            const NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'أنا'),
          ],
        ),
      ),
    );
  }
}
