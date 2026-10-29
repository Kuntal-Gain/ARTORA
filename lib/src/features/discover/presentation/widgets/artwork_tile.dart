import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/imports/imports.dart';

/// Masonry card: image with like / comment / bookmark overlay, then the artist.
///
/// With [isFollowing] set it shows the feed layout (name + Follow, title
/// below). Without it, the title sits under the name (search results).
class ArtworkTile extends StatelessWidget {
  const ArtworkTile({
    super.key,
    required this.artwork,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLike,
    required this.onBookmark,
    this.isFollowing,
    this.onFollow,
    this.onTap,
  });

  final Artwork artwork;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final bool? isFollowing;
  final VoidCallback? onFollow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final likes = artwork.likes + (isLiked ? 1 : 0);
    final following = isFollowing;

    return Material(
      color: colors.surface,
      borderRadius: AppBorders.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: artwork.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CommonImage(imageUrl: artwork.imageUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.transparent, AppColors.scrim],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          AppSpacing.lg,
                          0,
                          0,
                        ),
                        child: Row(
                          children: [
                            _OverlayStat(
                              icon: isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked ? colors.error : AppColors.white,
                              count: likes,
                              tooltip: LocaleKeys.discover_like.tr(),
                              onTap: onLike,
                            ),
                            AppSpacing.hGap(AppSpacing.ms),
                            _OverlayStat(
                              icon: Icons.chat_bubble_outline_rounded,
                              color: AppColors.white,
                              count: artwork.comments,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: onBookmark,
                              tooltip: LocaleKeys.discover_save.tr(),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 20.r,
                                color: isBookmarked
                                    ? colors.primary
                                    : AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: following == null
                  ? Row(
                      children: [
                        _ArtistAvatar(artist: artwork.artist, radius: 14),
                        AppSpacing.hGap(AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Name(artwork.artist.username),
                              Text(
                                artwork.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ArtistAvatar(artist: artwork.artist, radius: 12),
                            AppSpacing.hGap(AppSpacing.sm),
                            Expanded(child: _Name(artwork.artist.username)),
                            FollowPill(
                              isFollowing: following,
                              onPressed: onFollow,
                            ),
                          ],
                        ),
                        AppSpacing.vGap(AppSpacing.sm),
                        Text(
                          artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small Follow / Following pill. [filled] is the solid variant used on
/// artist cards; the default is outlined, as on feed tiles.
class FollowPill extends StatelessWidget {
  const FollowPill({
    super.key,
    required this.isFollowing,
    required this.onPressed,
    this.filled = false,
  });

  final bool isFollowing;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final solid = filled && !isFollowing;
    final foreground = isFollowing
        ? colors.onSurfaceVariant
        : (solid ? AppColors.textPrimary : colors.primary);

    return Material(
      color: solid ? AppColors.primaryPressed : AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.sm,
        side: BorderSide(
          color: isFollowing
              ? colors.outline
              : (solid ? AppColors.primaryPressed : colors.primary),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.ms,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            isFollowing
                ? LocaleKeys.discover_following.tr()
                : LocaleKeys.discover_follow.tr(),
            style: context.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({required this.artist, required this.radius});

  final Artist artist;
  final double radius;

  @override
  Widget build(BuildContext context) => AppAvatar(
    imageUrl: artist.avatarUrl,
    initials: artist.displayName,
    radius: radius,
  );
}

class _Name extends StatelessWidget {
  const _Name(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Text(
    name,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.textTheme.labelMedium?.copyWith(
      color: context.colors.onSurface,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _OverlayStat extends StatelessWidget {
  const _OverlayStat({
    required this.icon,
    required this.color,
    required this.count,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.r, color: color),
          AppSpacing.hGap(AppSpacing.xs),
          Text(
            formatCompact(count),
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: tooltip,
      child: InkResponse(onTap: onTap, child: content),
    );
  }
}
