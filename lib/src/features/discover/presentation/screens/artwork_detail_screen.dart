import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/providers/block_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/comments_section.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/features/discover/presentation/widgets/follow_button.dart';
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
        RequestInitial() || RequestLoading() => _loadingBody(context, id),
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

  /// Shown while the artwork loads: the loading image area, a skeleton artist
  /// row and the action row. Counts come from the feed card when it's there.
  Widget _loadingBody(BuildContext context, String id) {
    final feed = switch (ref.watch(feedProvider)) {
      RequestSuccess(:final data) => data,
      _ => const <Artwork>[],
    };
    final card = feed.where((a) => a.id == id).firstOrNull;
    final liked = ref.watch(likedProvider).contains(id);
    final saved = ref.watch(bookmarkedProvider).contains(id);

    Widget bar(double width, double height, {bool pill = false}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.shimmer,
            borderRadius: pill ? AppBorders.full : AppBorders.sm,
          ),
        );

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AppArtworkLoading(),
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: AppSpacing.xs,
                child: IconButton(
                  tooltip: LocaleKeys.common_back.tr(),
                  onPressed: () => context.pop(),
                  icon: const _OverlayIcon(AppIcons.back),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.md,
            AppSpacing.pagePadding,
            MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: const BoxDecoration(
                      color: AppColors.shimmer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.hGap(AppSpacing.ms),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(96.w, 12.h),
                      AppSpacing.vGap(AppSpacing.sm),
                      bar(64.w, 10.h),
                    ],
                  ),
                  const Spacer(),
                  bar(88.w, 36.h, pill: true),
                ],
              ),
              AppSpacing.vGap(AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Action(
                    icon: liked ? AppIcons.likeFilled : AppIcons.like,
                    color: liked ? AppColors.primary : null,
                    label: formatCompact(card?.likes ?? 0),
                    onTap: () {},
                  ),
                  _Action(
                    icon: AppIcons.comment,
                    label: formatCompact(card?.comments ?? 0),
                    onTap: () {},
                  ),
                  _Action(
                    icon: AppIcons.share,
                    label: LocaleKeys.common_share.tr(),
                    onTap: () {},
                  ),
                  _Action(
                    icon: saved ? AppIcons.bookmarkFilled : AppIcons.bookmark,
                    color: saved ? AppColors.primary : null,
                    label: LocaleKeys.discover_save.tr(),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    final isOwner = AppConfig.supabase.auth.currentUser?.id == art.userId;

    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = width / 0.8;
    // The image crops down to this height on scroll, then stays pinned while
    // the details scroll underneath it.
    final pinnedHeight = width * 0.6;
    // Rounded top edge of the details, overlapping the image's bottom.
    final overlap = AppSpacing.lg;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          expandedHeight: imageHeight,
          collapsedHeight: pinnedHeight,
          // Back and more live in the toolbar, so they stay put while scrolling.
          leading: IconButton(
            tooltip: LocaleKeys.common_back.tr(),
            onPressed: () => context.pop(),
            icon: const _OverlayIcon(AppIcons.back),
          ),
          actions: [
            PopupMenuButton<VoidCallback>(
              icon: const _OverlayIcon(AppIcons.more),
              color: AppColors.elevated,
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                if (isOwner)
                  PopupMenuItem(
                    value: () => context.push(AppRoutes.editArtworkPath(id)),
                    child: Text(LocaleKeys.common_edit.tr()),
                  ),
                PopupMenuItem(
                  value: () => ShareService.instance.shareText(art.title),
                  child: Text(LocaleKeys.common_share.tr()),
                ),
              ],
            ),
            AppSpacing.hGap(AppSpacing.xs),
          ],
          // Fills the bar, so the pager is cropped (not scrolled) as it shrinks.
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              PageView(
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final image in art.images)
                    CommonImage(
                      imageUrl: image.url,
                      fit: BoxFit.cover,
                      placeholder: const AppArtworkLoading(),
                    ),
                ],
              ),
              // Artist stacked on the bottom of the image, over a dark fade.
              if (artist != null && artist.username.isNotEmpty)
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
                        AppSpacing.pagePadding,
                        AppSpacing.xl,
                        AppSpacing.pagePadding,
                        overlap + AppSpacing.sm,
                      ),
                      child: _ArtistRow(artist: artist, showFollow: !isOwner),
                    ),
                  ),
                ),
              // Top centre, so it doesn't collide with the artist row.
              if (art.images.length > 1)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.md,
                  left: 0,
                  right: 0,
                  child: Center(
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
                ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(overlap),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: AppBorders.xl.topLeft,
                ),
              ),
              child: SizedBox(height: overlap, width: double.infinity),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ColoredBox(
            color: AppColors.background,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            onTap: () =>
                                context.push('${AppRoutes.search}?q=$tag'),
                          ),
                      ],
                    ),
                  ],
                  AppSpacing.vGap(AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Action(
                        icon: liked ? AppIcons.likeFilled : AppIcons.like,
                        color: liked ? AppColors.error : null,
                        label: formatCompact(likes),
                        onTap: () => toggleLikeOptimistic(ref, id),
                      ),
                      _Action(
                        icon: AppIcons.comment,
                        label: formatCompact(comments),
                        onTap: () =>
                            context.push(AppRoutes.artworkCommentsPath(id)),
                      ),
                      _Action(
                        icon: AppIcons.share,
                        label: LocaleKeys.common_share.tr(),
                        onTap: () => ShareService.instance.shareText(art.title),
                      ),
                      _Action(
                        icon:
                            saved ? AppIcons.bookmarkFilled : AppIcons.bookmark,
                        color: saved ? AppColors.primary : null,
                        label: LocaleKeys.discover_save.tr(),
                        onTap: () =>
                            ref.read(bookmarkedProvider.notifier).toggle(id),
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
                      title: LocaleKeys.artwork_related.tr(),
                      onSeeAll: () => context.go(AppRoutes.explore),
                    ),
                    AppSpacing.vGap(AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (related.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
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
                  onTap: () =>
                      context.push(AppRoutes.artworkDetailPath(related[i].id)),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          ),
        ),
      ],
    );
  }
}

/// White icon on a dark circle, so the buttons stay readable over any image.
class _OverlayIcon extends StatelessWidget {
  const _OverlayIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scrim,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, color: AppColors.white, size: 20.r),
      ),
    );
  }
}

class _ArtistRow extends ConsumerWidget {
  const _ArtistRow({required this.artist, required this.showFollow});

  final Artist artist;

  /// Off for your own artwork.
  final bool showFollow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = context.textTheme;
    final blocked =
        ref.watch(blockedIdsProvider.select((ids) => ids.contains(artist.id)));
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(AppRoutes.artistProfilePath(artist.id)),
            child: Row(
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              artist.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (blocked) ...[
                            AppSpacing.hGap(AppSpacing.sm),
                            const AppBlockedChip(),
                          ],
                        ],
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
              ],
            ),
          ),
        ),
        if (showFollow) ...[
          AppSpacing.hGap(AppSpacing.ms),
        ],
        if (showFollow) FollowButton(userId: artist.id),
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
