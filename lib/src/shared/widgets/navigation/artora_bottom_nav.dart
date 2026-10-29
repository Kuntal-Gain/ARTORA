import '../../../imports/imports.dart';

/// Bottom bar with Home / Explore / Saved / Profile and a raised create
/// button in the middle.
///
/// Wrap the host [Scaffold] with `extendBody: true` so content scrolls behind
/// the bar, and pad scrolling content by `MediaQuery.paddingOf(context).bottom`.
class ArtoraBottomNav extends StatelessWidget {
  const ArtoraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.onCreate,
  });

  /// Tab destinations, in bar order. The create button sits between 1 and 2.
  static const List<String> tabPaths = [
    AppRoutes.home,
    AppRoutes.explore,
    AppRoutes.saved,
    AppRoutes.profile,
  ];

  /// Create action until the upload flow exists.
  static void showCreateComingSoon() =>
      showGlobalToast(message: LocaleKeys.nav_create_coming_soon.tr());

  /// `null` on screens that aren't a tab (e.g. search): nothing is highlighted.
  final int? currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final fabSize = 56.r;
    final items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, LocaleKeys.nav_home.tr()),
      (Icons.search_rounded, Icons.saved_search_rounded, LocaleKeys.nav_explore.tr()),
      (
        Icons.bookmark_border_rounded,
        Icons.bookmark_rounded,
        LocaleKeys.nav_saved.tr(),
      ),
      (
        Icons.person_outline_rounded,
        Icons.person_rounded,
        LocaleKeys.nav_profile.tr(),
      ),
    ];

    Widget item(int index) {
      final (icon, activeIcon, label) = items[index];
      return Expanded(
        child: _NavItem(
          icon: icon,
          activeIcon: activeIcon,
          label: label,
          selected: index == currentIndex,
          onTap: () => onSelected(index),
        ),
      );
    }

    // The create button overlaps the top edge, so the bar starts half a button
    // lower and the button stays inside this widget's bounds (and tappable).
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: fabSize / 2),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorders.bottomSheet,
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64.h,
                child: Row(
                  children: [
                    item(0),
                    item(1),
                    SizedBox(width: fabSize + AppSpacing.md),
                    item(2),
                    item(3),
                  ],
                ),
              ),
            ),
          ),
        ),
        _CreateButton(size: fabSize, onPressed: onCreate),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, size: 24.r, color: color),
            AppSpacing.vGap(AppSpacing.xs),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.size, required this.onPressed});

  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LocaleKeys.nav_create.tr(),
      excludeSemantics: true,
      child: Material(
        color: AppColors.primaryPressed,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: AppColors.primaryPressed,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.add_rounded,
              size: 30.r,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
