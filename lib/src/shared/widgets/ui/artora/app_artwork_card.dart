import '../../../../imports/imports.dart';

/// Artwork tile: image, optional like overlay, artist footer and stats.
///
/// Usage:
/// ```dart
/// AppArtworkCard(
///   imageUrl: art.url,
///   artistName: 'Kairo',
///   artistHandle: '@kairo.arts',
///   artistAvatarUrl: art.artist.avatar,
///   likes: 1100,
///   comments: 64,
///   isLiked: art.isLiked,
///   onLikeChanged: (v) => toggleLike(art, v),
///   onTap: () => context.push('/artwork/${art.id}'),
/// )
/// ```
class AppArtworkCard extends StatelessWidget {
  const AppArtworkCard({
    super.key,
    required this.imageUrl,
    required this.artistName,
    this.artistHandle,
    this.artistAvatarUrl,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.onLikeChanged,
    this.onTap,
    this.aspectRatio = 0.8,
  });

  final String imageUrl;
  final String artistName;
  final String? artistHandle;
  final String? artistAvatarUrl;
  final int likes;
  final int comments;
  final bool isLiked;
  final ValueChanged<bool>? onLikeChanged;
  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Material(
      color: cs.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: AppBorders.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: LayoutBuilder(
                    builder: (_, c) => CommonImage(
                      imageUrl: imageUrl,
                      width: c.maxWidth,
                      height: c.maxHeight,
                    ),
                  ),
                ),
                if (onLikeChanged != null || isLiked)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.imageOverlay,
                        borderRadius: AppBorders.full,
                      ),
                      child: AppToggleIconButton(
                        icon: Icons.favorite_border_rounded,
                        activeIcon: Icons.favorite_rounded,
                        isActive: isLiked,
                        activeColor: cs.error,
                        bordered: false,
                        onChanged: onLikeChanged,
                        tooltip: 'Like',
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: artistAvatarUrl,
                    initials: artistName,
                    radius: 14,
                  ),
                  AppSpacing.hGap(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (artistHandle != null)
                          Text(
                            artistHandle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  _Stat(icon: Icons.favorite_border_rounded, count: likes),
                  AppSpacing.hGap(AppSpacing.sm),
                  _Stat(icon: Icons.chat_bubble_outline_rounded, count: comments),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: AppSpacing.xs),
        Text(
          formatCompact(count),
          style: context.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
