import 'package:artora/src/imports/imports.dart';

/// Logo, notifications bell and the user's avatar, as on home and explore.
class ArtoraTopBar extends StatelessWidget {
  const ArtoraTopBar({
    super.key,
    this.avatarUrl,
    this.avatarInitials,
    this.hasUnread = false,
    this.onNotifications,
    this.onAvatarTap,
  });

  final String? avatarUrl;
  final String? avatarInitials;
  final bool hasUnread;
  final VoidCallback? onNotifications;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.ms,
      ),
      child: Row(
        children: [
          const ArtoraWordmark(),
          const Spacer(),
          IconButton(
            onPressed: onNotifications,
            tooltip: LocaleKeys.discover_notifications.tr(),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 26.r,
                  color: colors.onSurface,
                ),
                if (hasUnread)
                  Positioned(
                    top: 2.r,
                    right: 2.r,
                    child: Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: colors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.hGap(AppSpacing.xs),
          Semantics(
            button: true,
            label: LocaleKeys.nav_profile.tr(),
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 1.5.r),
                ),
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  initials: avatarInitials,
                  radius: 17,
                ),
              ),
            ),
          ),
          AppSpacing.hGap(AppSpacing.sm),
        ],
      ),
    );
  }
}

/// "A" mark plus letter-spaced ARTORA. The mark is cropped out of the stacked
/// logo asset, so no separate icon file is needed.
class ArtoraWordmark extends StatelessWidget {
  const ArtoraWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Artora',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: Align(
              alignment: const Alignment(0, -0.3),
              widthFactor: 0.45,
              heightFactor: 0.4,
              child: Image.asset(AppAssets.logo, width: 76.r),
            ),
          ),
          AppSpacing.hGap(AppSpacing.ms),
          Text(
            'ARTORA',
            style: context.textTheme.titleLarge?.copyWith(
              fontFamily: AppFonts.sora,
              fontWeight: FontWeight.w400,
              letterSpacing: 6.r,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
