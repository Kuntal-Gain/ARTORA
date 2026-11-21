import '../../../../imports/imports.dart';

/// Follow button with four states:
/// - **Follow**: filled primary.
/// - **Following**: outlined, with a check (tap to unfollow).
/// - **Loading...**: muted, with a spinner; not tappable.
/// - **Follow Back**: filled primary, when they follow you and you don't
///   follow them.
///
/// Usage:
/// ```dart
/// AppFollowButton(
///   isFollowing: false,
///   followsMe: true,       // -> Follow Back
///   isLoading: pending,
///   onPressed: _toggleFollow,
/// )
/// ```
class AppFollowButton extends StatelessWidget {
  const AppFollowButton({
    super.key,
    required this.isFollowing,
    this.followsMe = false,
    this.onPressed,
    this.isLoading = false,
    this.height = ButtonSize.small,
    this.width,
  });

  final bool isFollowing;

  /// They follow you: the not-following label becomes Follow Back.
  final bool followsMe;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize height;

  /// Fixed width; `null` sizes to the label.
  final double? width;

  double get _height => switch (height) {
        ButtonSize.small => 36.h,
        ButtonSize.medium => 48.h,
        ButtonSize.large => 56.h,
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final filled = !isFollowing && !isLoading;

    final (Color background, Color border, Color foreground) = isLoading
        ? (cs.surfaceContainerHigh, cs.outlineVariant, cs.onSurfaceVariant)
        : isFollowing
            ? (AppColors.transparent, cs.primary.withValues(alpha: 0.5), cs.onSurface)
            : (cs.primary, cs.primary, cs.onPrimary);

    final label = isLoading
        ? LocaleKeys.common_loading.tr()
        : isFollowing
            ? LocaleKeys.discover_following.tr()
            : followsMe
                ? LocaleKeys.follow_list_follow_back.tr()
                : LocaleKeys.discover_follow.tr();

    final Widget? leading = isLoading
        ? SizedBox.square(
            dimension: 14.r,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          )
        : isFollowing
            ? Icon(AppIcons.checkmark, size: 16.r, color: foreground)
            : null;

    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: _height,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.md,
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Row(
                  key: ValueKey(label),
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading,
                      AppSpacing.hGap(AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
