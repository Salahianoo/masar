import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


/// Bottom navigation with the 3 tabs: مساري · خزنة · أنا.
/// The tabs also sit side by side in a pager, so a swipe moves between them;
/// a tap on the bar (or any `go` to a tab) slides there the same way.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell, required this.children});

  final StatefulNavigationShell navigationShell;

  /// One navigator per tab, from go_router.
  final List<Widget> children;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pages = PageController(initialPage: widget.navigationShell.currentIndex);

  /// True while the pager slides because of a tap, so the pages it passes on
  /// the way don't count as the student choosing them.
  bool _sliding = false;

  @override
  void didUpdateWidget(AppShell old) {
    super.didUpdateWidget(old);
    final target = widget.navigationShell.currentIndex;
    if (_pages.hasClients && (_pages.page ?? target).round() != target) _slideTo(target);
  }

  Future<void> _slideTo(int index) async {
    _sliding = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      await _pages.animateToPage(index,
          duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
    _sliding = false;
  }

  void _settle() {
    if (!_pages.hasClients) return;
    _sliding = false;
    final shown = (_pages.page ?? 0).round();
    if (shown != widget.navigationShell.currentIndex) widget.navigationShell.goBranch(shown);
  }

  void _onSwiped(int index) {
    if (_sliding || index == widget.navigationShell.currentIndex) return;
    widget.navigationShell.goBranch(index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    return Scaffold(
      body: NotificationListener<ScrollEndNotification>(
        // Whenever the pager comes to rest, the bar follows the page actually on
        // screen. This also covers a slide cut short by a touch halfway through.
        onNotification: (n) {
          if (n.depth == 0) _settle();
          return false;
        },
        child: PageView(
          controller: _pages,
          onPageChanged: _onSwiped,
          children: [for (final child in widget.children) _KeepAlive(child: child)],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.route_outlined), label: 'مساري'),
            const NavigationDestination(icon: Icon(Icons.auto_stories_outlined), label: 'خزنة'),
            const NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'أنا'),
          ],
        ),
      ),
    );
  }
}

/// Keeps a tab alive while it's swiped off screen, so its scroll position
/// and chat don't reset.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
