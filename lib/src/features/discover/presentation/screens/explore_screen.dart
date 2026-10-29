import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/screens/search_screen.dart';
import 'package:artora/src/features/discover/presentation/widgets/artora_top_bar.dart';
import 'package:artora/src/features/discover/presentation/widgets/discover_search_bar.dart';
import 'package:artora/src/features/discover/presentation/widgets/explore_widgets.dart';
import 'package:artora/src/imports/imports.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = switch (ref.watch(currentArtistProvider)) {
      RequestSuccess(:final data) => data,
      _ => null,
    };
    final explore = ref.watch(filteredExploreProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(exploreProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ArtoraTopBar(
                  avatarUrl: me?.avatarUrl,
                  avatarInitials: me?.displayName,
                  onNotifications: () => showGlobalToast(
                    message: LocaleKeys.discover_notifications_coming_soon.tr(),
                  ),
                  onAvatarTap: () => context.go(AppRoutes.profile),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                sliver: SliverToBoxAdapter(
                  child: DiscoverSearchBar(
                    hint: LocaleKeys.discover_search_hint_explore.tr(),
                    onTap: () => SearchScreen.open(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: switch (explore) {
                  RequestInitial() || RequestLoading() =>
                    const _ExploreSkeleton(),
                  RequestFailure() => Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: AppErrorPresets.network(
                      onRetry: () =>
                          ref.read(exploreProvider.notifier).refresh(),
                    ),
                  ),
                  RequestSuccess(:final data) => _ExploreContent(content: data),
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreContent extends ConsumerWidget {
  const _ExploreContent({required this.content});

  final ExploreContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(exploreCategoryProvider);
    final following = ref.watch(followingProvider);
    final categories = content.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vGap(AppSpacing.md),
        HorizontalStrip(
          height: 42.h,
          gap: AppSpacing.sm,
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            final name = index == 0 ? null : categories[index - 1].name;
            return Center(
              child: SelectablePill(
                label: name ?? LocaleKeys.discover_all.tr(),
                selected: selectedCategory == name,
                onTap: () =>
                    ref.read(exploreCategoryProvider.notifier).state = name,
              ),
            );
          },
        ),
        AppSpacing.vGap(AppSpacing.md),
        HorizontalStrip(
          height: 104.r,
          itemCount: categories.length,
          itemBuilder: (context, index) => CategoryTile(
            category: categories[index],
            onTap: () => SearchScreen.open(
              context,
              query: categories[index].name,
              scope: SearchScope.artwork,
            ),
          ),
        ),
        AppSpacing.vGap(AppSpacing.sm),
        SectionHeader(
          title: LocaleKeys.discover_trending_tags.tr(),
          onAction: () => SearchScreen.open(context, scope: SearchScope.tags),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in content.trendingTags.take(8))
                SelectablePill(
                  label: '#$tag',
                  onTap: () => SearchScreen.open(context, query: tag),
                ),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.md),
        SectionHeader(
          title: LocaleKeys.discover_curated_collections.tr(),
          onAction: () => SearchScreen.open(context),
        ),
        HorizontalStrip(
          height: 136.h,
          itemCount: content.collections.length,
          itemBuilder: (context, index) =>
              CollectionCard(collection: content.collections[index]),
        ),
        if (content.artists.isNotEmpty) ...[
          AppSpacing.vGap(AppSpacing.md),
          SectionHeader(
            title: LocaleKeys.discover_discover_artists.tr(),
            onAction: () =>
                SearchScreen.open(context, scope: SearchScope.artists),
          ),
          HorizontalStrip(
            height: 172.r,
            itemCount: content.artists.length,
            itemBuilder: (context, index) {
              final artist = content.artists[index];
              return ArtistCard(
                artist: artist,
                isFollowing: following.contains(artist.id),
                onFollow: () =>
                    ref.read(followingProvider.notifier).toggle(artist.id),
              );
            },
          ),
        ],
        if (content.editorsPicks.isNotEmpty) ...[
          AppSpacing.vGap(AppSpacing.sm),
          SectionHeader(
            title: LocaleKeys.discover_editors_picks.tr(),
            onAction: () =>
                SearchScreen.open(context, scope: SearchScope.artwork),
          ),
          HorizontalStrip(
            height: 96.h,
            itemCount: content.editorsPicks.length,
            itemBuilder: (context, index) =>
                EditorPickTile(artwork: content.editorsPicks[index]),
          ),
        ],
      ],
    );
  }
}

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double width, double height, BorderRadius radius) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.shimmer, borderRadius: radius),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        0,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final width in [48.0, 120.0, 72.0, 130.0]) ...[
                box(width.w, 36.h, AppBorders.md),
                AppSpacing.hGap(AppSpacing.sm),
              ],
            ],
          ),
          AppSpacing.vGap(AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                box(62.r, 62.r, AppBorders.lg),
                AppSpacing.hGap(AppSpacing.ms),
              ],
            ],
          ),
          AppSpacing.vGap(AppSpacing.lg),
          box(140.w, 18.h, AppBorders.sm),
          AppSpacing.vGap(AppSpacing.md),
          Row(
            children: [
              box(220.w, 136.h, AppBorders.card),
              AppSpacing.hGap(AppSpacing.ms),
              Expanded(child: box(double.infinity, 136.h, AppBorders.card)),
            ],
          ),
        ],
      ),
    );
  }
}
