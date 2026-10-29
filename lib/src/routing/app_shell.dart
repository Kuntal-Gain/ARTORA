import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/shared/widgets/navigation/artora_bottom_nav.dart';

/// Hosts the four tab branches under the shared bottom bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ArtoraBottomNav(
        currentIndex: navigationShell.currentIndex,
        // Re-tapping the active tab returns it to its first page.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onCreate: ArtoraBottomNav.showCreateComingSoon,
      ),
    );
  }
}
