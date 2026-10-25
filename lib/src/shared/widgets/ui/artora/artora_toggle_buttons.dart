import '../../../../imports/imports.dart';

/// Square toggle icon button (like / bookmark) with a pop animation.
///
/// Usage:
/// ```dart
/// AppToggleIconButton(
///   icon: Icons.favorite_border_rounded,
///   activeIcon: Icons.favorite_rounded,
///   isActive: liked,
///   onChanged: (v) => ref.read(likeProvider.notifier).set(v),
/// )
/// ```
class AppToggleIconButton extends StatelessWidget {
  const AppToggleIconButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    this.onChanged,
    this.activeColor,
    this.bordered = true,
    this.tooltip,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final bool bordered;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final fg = isActive ? (activeColor ?? cs.primary) : cs.onSurfaceVariant;

    final button = InkWell(
      borderRadius: AppBorders.md,
      onTap: onChanged == null ? null : () => onChanged!(!isActive),
      child: Container(
        width: AppSpacing.touchTarget,
        height: AppSpacing.touchTarget,
        alignment: Alignment.center,
        decoration: bordered
            ? BoxDecoration(
                borderRadius: AppBorders.md,
                border: Border.all(color: cs.outline),
              )
            : null,
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isActive ? activeIcon : icon,
            key: ValueKey(isActive),
            size: 24.sp,
            color: fg,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      toggled: isActive,
      label: tooltip,
      child: tooltip == null ? button : Tooltip(message: tooltip!, child: button),
    );
  }
}

/// Heart toggle for liking artwork.
class AppLikeButton extends StatelessWidget {
  const AppLikeButton({
    super.key,
    required this.isLiked,
    this.onChanged,
    this.bordered = true,
  });

  final bool isLiked;
  final ValueChanged<bool>? onChanged;
  final bool bordered;

  @override
  Widget build(BuildContext context) => AppToggleIconButton(
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        isActive: isLiked,
        activeColor: context.colors.error,
        onChanged: onChanged,
        bordered: bordered,
        tooltip: 'Like',
      );
}

/// Bookmark toggle for saving artwork.
class AppBookmarkButton extends StatelessWidget {
  const AppBookmarkButton({
    super.key,
    required this.isSaved,
    this.onChanged,
    this.bordered = true,
  });

  final bool isSaved;
  final ValueChanged<bool>? onChanged;
  final bool bordered;

  @override
  Widget build(BuildContext context) => AppToggleIconButton(
        icon: Icons.bookmark_border_rounded,
        activeIcon: Icons.bookmark_rounded,
        isActive: isSaved,
        onChanged: onChanged,
        bordered: bordered,
        tooltip: 'Save',
      );
}
