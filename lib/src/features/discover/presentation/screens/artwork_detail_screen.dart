import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/comments_section.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/features/discover/state/comments_provider.dart';
import 'package:artora/src/imports/imports.dart';

/// Post view: image pager under a rounded details panel, artist row, tags,
/// actions, comments header and related artwork.
class ArtworkDetailScreen extends ConsumerStatefulWidget {
  const ArtworkDetailScreen({super.key, required this.artworkId});

  final String artworkId;

  @override
  ConsumerState<ArtworkDetailScreen> createState() =>
      _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends ConsumerState<ArtworkDetailScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final id = widget.artworkId;
    final post = ref.watch(artworkDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (post) {
        RequestInitial() || RequestLoading() => const AppLoading(),
        RequestFailure(:final failure) => SafeArea(
            child: AppErrorWidget(
              message: failure.message,
              onRetry: () =>
                  ref.read(artworkDetailProvider(id).notifier).fetch(),
            ),
          ),
        RequestSuccess(:final data) => _body(context, data),
      },
    );
  }

  Widget _body(BuildContext context, ArtworkModel art) {
    final textTheme = context.textTheme;
    final id = art.id;
    final liked = ref.watch(likedProvider).contains(id);
    final saved = ref.watch(bookmarkedProvider).contains(id);
    final feed = switch (ref.watch(feedProvider)) {
      RequestSuccess(:final data) => data,
      _ => const <Artwork>[],
    };
    // Counts (and followers) still come from the feed card when it's loaded.
    final card = feed.where((a) => a.id == id).firstOrNull;
    final profile = art.artist;
    final artist = profile == null
        ? null
        : Artist(
            id: profile.id,
            username: profile.username,
            displayName: profile.displayName,
            avatarUrl: profile.avatarUrl ?? '',
            followers: card?.artist.followers ?? 0,
            specialties: profile.specialties,
          );
    final likes = card?.likes ?? art.likesCount;
    final comments = switch (ref.watch(commentsProvider(id))) {
      RequestSuccess(:final data) => data.total,
      _ => card?.comments ?? 0,
    };
    final related = feed
        .where((a) => a.id != id && a.category == (art.category?.name ?? ''))
        .take(6)
        .toList();
    final following =
        artist != null && ref.watch(followingProvider).contains(artist.id);
    final isOwner = AppConfig.supabase.auth.currentUser?.id == art.userId;

    final imageHeight = MediaQuery.sizeOf(context).width / 0.8;
    final overlap = AppSpacing.lg;

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      children: [
        Stack(
          children: [
            SizedBox(
              height: imageHeight,
              child: PageView(
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final image in art.images)
                    CommonImage(imageUrl: image.url, fit: BoxFit.cover),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      AppIcons.back,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<VoidCallback>(
                    icon: const Icon(
                      AppIcons.more,
                      color: AppColors.white,
                    ),
                    color: AppColors.elevated,
                    onSelected: (action) => action(),
                    itemBuilder: (context) => [
                      if (isOwner)
                        PopupMenuItem(
                          value: () =>
                              context.push(AppRoutes.editArtworkPath(id)),
                          child: const Text('Edit'),
                        ),
                      PopupMenuItem(
                        value: () =>
                            ShareService.instance.shareText(art.title),
                        child: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (art.images.length > 1)
              Positioned(
                right: AppSpacing.md,
                bottom: overlap + AppSpacing.sm,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.scrim,
                    borderRadius: AppBorders.full,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      '${_page + 1}/${art.images.length}',
                      style: textTheme.labelMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ),
            // Details panel overlapping the image's bottom edge.
            Padding(
              padding: EdgeInsets.only(top: imageHeight - overlap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: AppBorders.xl.topLeft,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (artist != null && artist.username.isNotEmpty) ...[
                        _ArtistRow(
                          artist: artist,
                          following: following,
                          onFollow: () => ref
                              .read(followingProvider.notifier)
                              .toggle(artist.id),
                        ),
                        AppSpacing.vGap(AppSpacing.md),
                      ],
                      Text(
                        art.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (art.description?.isNotEmpty ?? false) ...[
                        AppSpacing.vGap(AppSpacing.xs),
                        Text(
                          art.description!,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      if (art.tags.isNotEmpty) ...[
                        AppSpacing.vGap(AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final tag in art.tags)
                              _TagPill(
                                tag: tag,
                                onTap: () => context
                                    .push('${AppRoutes.search}?q=$tag'),
                              ),
                          ],
                        ),
                      ],
                      AppSpacing.vGap(AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Action(
                            icon: liked
                                ? AppIcons.likeFilled
                                : AppIcons.like,
                            color: liked ? AppColors.error : null,
                            label: formatCompact(likes),
                            onTap: () => toggleLikeOptimistic(ref, id),
                          ),
                          _Action(
                            icon: AppIcons.comment,
                            label: formatCompact(comments),
                            onTap: () => context
                                .push(AppRoutes.artworkCommentsPath(id)),
                          ),
                          _Action(
                            icon: AppIcons.share,
                            label: 'Share',
                            onTap: () =>
                                ShareService.instance.shareText(art.title),
                          ),
                          _Action(
                            icon: saved
                                ? AppIcons.bookmarkFilled
                                : AppIcons.bookmark,
                            color: saved ? AppColors.primary : null,
                            label: LocaleKeys.discover_save.tr(),
                            onTap: () => ref
                                .read(bookmarkedProvider.notifier)
                                .toggle(id),
                          ),
                        ],
                      ),
                      AppSpacing.vGap(AppSpacing.sm),
                      const Divider(color: AppColors.divider, height: 1),
                      AppSpacing.vGap(AppSpacing.md),
                      CommentsPreview(artworkId: id, ownerId: art.userId),
                      if (related.isNotEmpty) ...[
                        AppSpacing.vGap(AppSpacing.lg),
                        _SectionHeader(
                          title: 'Related Artwork',
                          onSeeAll: () => context.go(AppRoutes.explore),
                        ),
                        AppSpacing.vGap(AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (related.isNotEmpty)
          SizedBox(
            height: 170.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              itemCount: related.length,
              separatorBuilder: (_, __) => AppSpacing.hGap(AppSpacing.sm),
              itemBuilder: (context, i) => _RelatedTile(
                artwork: related[i],
                onTap: () => context
                    .push(AppRoutes.artworkDetailPath(related[i].id)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({
    required this.artist,
    required this.following,
    required this.onFollow,
  });

  final Artist artist;
  final bool following;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Row(
      children: [
        AppAvatar(
          imageUrl: artist.avatarUrl,
          initials: artist.displayName,
          radius: 22,
        ),
        AppSpacing.hGap(AppSpacing.ms),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                artist.username,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                LocaleKeys.discover_followers.tr(
                  namedArgs: {'count': formatCompact(artist.followers)},
                ),
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Material(
          color: following
              ? AppColors.transparent
              : AppColors.primary.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.md,
            side: BorderSide(
              color: following ? AppColors.border : AppColors.primary,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onFollow,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                following
                    ? LocaleKeys.discover_following.tr()
                    : LocaleKeys.discover_follow.tr(),
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: following
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag, required this.onTap});

  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.elevated,
        borderRadius: AppBorders.full,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.ms,
              vertical: AppSpacing.xs + 2,
            ),
            child: Text(
              '#$tag',
              style: context.textTheme.labelMedium
                  ?.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: AppBorders.sm,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24.r, color: color ?? AppColors.textPrimary),
              AppSpacing.hGap(AppSpacing.sm),
              Text(
                label,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: onSeeAll,
            child: Text(
              LocaleKeys.discover_see_all.tr(),
              style: context.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

class _RelatedTile extends StatelessWidget {
  const _RelatedTile({required this.artwork, required this.onTap});

  final Artwork artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 0.85,
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.card,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: CommonImage(imageUrl: artwork.imageUrl, fit: BoxFit.cover),
          ),
        ),
      );
}
