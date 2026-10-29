import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/widgets/artwork_tile.dart';
import 'package:artora/src/imports/imports.dart';

/// Bold section title with an optional trailing link ("See All" by default).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel ?? LocaleKeys.discover_see_all.tr(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded pill used for category chips and `#tag`s. Selected pills are solid
/// purple; the rest are outlined.
class SelectablePill extends StatelessWidget {
  const SelectablePill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryPressed : AppColors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.md,
          side: BorderSide(
            color: selected ? AppColors.primaryPressed : colors.outline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.textPrimary : colors.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square-ish thumbnail with the category name underneath.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, this.onTap});

  final ArtCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = 62.r;

    return Semantics(
      button: true,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorders.md,
        child: SizedBox(
          width: 70.r,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: AppBorders.lg,
                child: CommonImage(
                  imageUrl: category.imageUrl,
                  width: size,
                  height: size,
                ),
              ),
              AppSpacing.vGap(AppSpacing.xs),
              Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colors.onSurface,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide cover with the collection title and artwork count over a gradient.
class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.collection, this.onTap});

  final ArtCollection collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return SizedBox(
      width: 220.w,
      child: Material(
        borderRadius: AppBorders.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CommonImage(imageUrl: collection.coverUrl, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.transparent, AppColors.scrim],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.ms,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      LocaleKeys.discover_artworks_count.tr(
                        namedArgs: {'count': '${collection.artworkCount}'},
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ringed avatar, name, follower count and a solid Follow pill.
class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    required this.isFollowing,
    required this.onFollow,
  });

  final Artist artist;
  final bool isFollowing;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return SizedBox(
      width: 78.r,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(2.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 2.r),
            ),
            child: AppAvatar(
              imageUrl: artist.avatarUrl,
              initials: artist.displayName,
              radius: 28,
            ),
          ),
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            artist.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            LocaleKeys.discover_followers.tr(
              namedArgs: {'count': formatCompact(artist.followers)},
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap(AppSpacing.sm),
          FollowPill(isFollowing: isFollowing, onPressed: onFollow, filled: true),
        ],
      ),
    );
  }
}

/// Landscape thumbnail for the editor's picks strip.
class EditorPickTile extends StatelessWidget {
  const EditorPickTile({super.key, required this.artwork, this.onTap});

  final Artwork artwork;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: artwork.title,
      image: true,
      child: SizedBox(
        width: 132.w,
        child: Material(
          borderRadius: AppBorders.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: CommonImage(imageUrl: artwork.imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// Horizontal strip with page-aligned padding and even gaps.
class HorizontalStrip extends StatelessWidget {
  const HorizontalStrip({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.gap,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        itemCount: itemCount,
        separatorBuilder: (_, __) => AppSpacing.hGap(gap ?? AppSpacing.ms),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
