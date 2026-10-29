import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/screens/search_screen.dart';
import 'package:artora/src/features/discover/presentation/widgets/artora_top_bar.dart';
import 'package:artora/src/features/discover/presentation/widgets/artwork_masonry.dart';
import 'package:artora/src/features/discover/presentation/widgets/discover_search_bar.dart';
import 'package:artora/src/features/discover/presentation/widgets/masonry_grid.dart';
import 'package:artora/src/features/discover/presentation/widgets/underline_tabs.dart';
import 'package:artora/src/imports/imports.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  bool _showFollowing = false;

  @override
  Widget build(BuildContext context) {
    final me = switch (ref.watch(currentArtistProvider)) {
      RequestSuccess(:final data) => data,
      _ => null,
    };
    final feed = ref.watch(_showFollowing ? followingFeedProvider : feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ArtoraTopBar(
                  avatarUrl: me?.avatarUrl,
                  avatarInitials: me?.displayName,
                  hasUnread: true,
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
                    hint: LocaleKeys.discover_search_hint_home.tr(),
                    onTap: () => SearchScreen.open(context),
                    onFilter: () => SearchScreen.open(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: UnderlineTabs(
                    labels: [
                      LocaleKeys.discover_for_you.tr(),
                      LocaleKeys.discover_following.tr(),
                    ],
                    selectedIndex: _showFollowing ? 1 : 0,
                    onSelected: (index) =>
                        setState(() => _showFollowing = index == 1),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: switch (feed) {
                    RequestInitial() || RequestLoading() =>
                      const MasonrySkeleton(),
                    RequestFailure() => AppErrorPresets.network(
                      onRetry: () => ref.read(feedProvider.notifier).refresh(),
                    ),
                    RequestSuccess(:final data) when data.isEmpty =>
                      AppEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: LocaleKeys.discover_following_empty_title.tr(),
                        subtitle: LocaleKeys.discover_following_empty_subtitle
                            .tr(),
                        actionLabel: LocaleKeys.nav_explore.tr(),
                        onAction: () => context.go(AppRoutes.explore),
                      ),
                    RequestSuccess(:final data) => ArtworkMasonry(
                      artworks: data,
                      showFollow: true,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
