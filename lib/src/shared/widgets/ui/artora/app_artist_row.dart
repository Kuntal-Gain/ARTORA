import '../../../../imports/imports.dart';

/// Name line with an optional verified badge.
class AppArtistName extends StatelessWidget {
  const AppArtistName({super.key, required this.name, this.isVerified = false});

  final String name;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (isVerified) ...[
          SizedBox(width: AppSpacing.xs),
          Icon(Icons.verified_rounded, size: 16.sp, color: context.colors.primary),
        ],
      ],
    );
  }
}

/// Artist list row: avatar, name, handle, bio and a follow action.
///
/// Usage:
/// ```dart
/// AppArtistRow(
///   name: 'Luna Art',
///   handle: '@lunaart',
///   bio: 'Digital artist & concept artist',
///   isVerified: true,
///   isFollowing: false,
///   onFollow: _toggleFollow,
/// )
/// ```
class AppArtistRow extends StatelessWidget {
  const AppArtistRow({
    super.key,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.bio,
    this.isVerified = false,
    this.isFollowing,
    this.onFollow,
    this.onTap,
    this.onMore,
  });

  final String name;
  final String handle;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;

  /// `null` hides the follow button.
  final bool? isFollowing;
  final VoidCallback? onFollow;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return InkWell(
      borderRadius: AppBorders.md,
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.insetListTile,
        child: Row(
          children: [
            AppAvatar(imageUrl: avatarUrl, initials: name, radius: 24),
            AppSpacing.hGap(AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppArtistName(name: name, isVerified: isVerified),
                  Text(
                    handle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (bio != null)
                    Text(
                      bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (isFollowing != null) ...[
              AppSpacing.hGap(AppSpacing.sm),
              AppFollowButton(isFollowing: isFollowing!, onPressed: onFollow),
            ],
            if (onMore != null)
              IconButton(
                onPressed: onMore,
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
