import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/screens/search_screen.dart';
import 'package:artora/src/features/discover/presentation/widgets/artora_top_bar.dart';
import 'package:artora/src/features/discover/presentation/widgets/artwork_masonry.dart';
import 'package:artora/src/features/discover/presentation/widgets/discover_search_bar.dart';
import 'package:artora/src/features/discover/presentation/widgets/masonry_grid.dart';
import 'package:artora/src/features/notifications/presentation/providers/notification_providers.dart';
import 'package:artora/src/imports/imports.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = switch (ref.watch(currentArtistProvider)) {
      RequestSuccess(:final data) => data,
      _ => null,
    };
    final colors = context.colors;
    final labelStyle = context.textTheme.titleMedium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ArtoraTopBar(
              avatarUrl: me?.avatarUrl,
              avatarInitials: me?.displayName,
              hasUnread: ref.watch(unreadNotificationsProvider) > 0,
              onNotifications: () => context.push(AppRoutes.notifications),
              onAvatarTap: () => context.go(AppRoutes.profile),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              child: DiscoverSearchBar(
                hint: LocaleKeys.discover_search_hint_home.tr(),
                onTap: () => SearchScreen.open(context),
                onFilter: () => SearchScreen.open(context),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                0,
              ),
              child: TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: LocaleKeys.discover_for_you.tr()),
                  Tab(text: LocaleKeys.discover_following.tr()),
                ],
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: labelStyle?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    labelStyle?.copyWith(fontWeight: FontWeight.w500),
                dividerColor: colors.outlineVariant,
                dividerHeight: 1,
                overlayColor: const WidgetStatePropertyAll(
                  AppColors.transparent,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: colors.primary, width: 3.r),
                  borderRadius: AppBorders.full,
                  insets: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _FeedTab(following: false),
                  _FeedTab(following: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One swipeable page of the home feed with its own pull-to-refresh.
class _FeedTab extends ConsumerStatefulWidget {
  const _FeedTab({required this.following});

  final bool following;

  @override
  ConsumerState<_FeedTab> createState() => _FeedTabState();
}

// Keeps the scroll position when swiping between the two pages.
class _FeedTabState extends ConsumerState<_FeedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() => widget.following
      ? ref.read(followingFeedProvider.notifier).refresh()
      : ref.read(feedProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final feed = ref
        .watch(widget.following ? followingFeedProvider : feedProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // Scrollable even when short, so pull-to-refresh always works.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
        ),
        children: [
          switch (feed) {
            RequestInitial() || RequestLoading() => const MasonrySkeleton(),
            RequestFailure() => AppErrorPresets.network(onRetry: _refresh),
            RequestSuccess(:final data) when data.isEmpty => AppEmptyState(
                icon: AppIcons.people,
                title: LocaleKeys.discover_following_empty_title.tr(),
                subtitle: LocaleKeys.discover_following_empty_subtitle.tr(),
                actionLabel: LocaleKeys.nav_explore.tr(),
                onAction: () => context.go(AppRoutes.explore),
              ),
            RequestSuccess(:final data) =>
              ArtworkMasonry(artworks: data, showFollow: true),
          },
        ],
      ),
    );
  }
}
