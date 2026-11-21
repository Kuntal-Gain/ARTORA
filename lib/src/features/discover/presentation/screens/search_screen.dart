import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/providers/block_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/artwork_masonry.dart';
import 'package:artora/src/features/discover/presentation/widgets/explore_widgets.dart';
import 'package:artora/src/features/discover/presentation/widgets/masonry_grid.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/shared/widgets/navigation/artora_bottom_nav.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery = '',
    this.initialScope = SearchScope.all,
  });

  final String initialQuery;
  final SearchScope initialScope;

  /// Pushes the search screen, optionally pre-filled with a query and scope.
  static void open(BuildContext context, {String? query, SearchScope? scope}) {
    final params = {
      if (query != null && query.isNotEmpty) 'q': query,
      if (scope != null) 'scope': scope.name,
    };
    context.push(
      Uri(
        path: AppRoutes.search,
        queryParameters: params.isEmpty ? null : params,
      ).toString(),
    );
  }

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with TickerProviderStateMixin {
  static const int _visibleRecent = 5;

  // Only drives the TabBar indicator; [_scope] stays the source of truth.
  late final TabController _tabs = TabController(
    length: SearchScope.values.length,
    vsync: this,
    initialIndex: widget.initialScope.index,
  );

  // Same idea for the result-type tabs under "All" (no "All" entry).
  late final TabController _resultTabs = TabController(
    length: SearchScope.values.length - 1,
    vsync: this,
  );

  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focusNode = FocusNode();
  late SearchScope _scope = widget.initialScope;

  /// Result type shown under "Results" while the top tab is "All".
  SearchScope _resultTab = SearchScope.artwork;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      // Providers can't be modified while the first frame is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _resultTabs.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  void _onChanged(String value) {
    setState(() {});
    ref.read(searchProvider.notifier).search(value);
  }

  void _submit(String raw) {
    final query = raw.trim();
    if (query.isEmpty) return;
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    setState(() {});
    _focusNode.unfocus();
    ref.read(searchProvider.notifier).search(query, immediate: true);
    ref.read(recentSearchesProvider.notifier).add(query);
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    ref.read(searchProvider.notifier).search('');
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recent = ref.watch(recentSearchesProvider);
    final trending = ref.watch(trendingTagsProvider);
    final results = ref.watch(searchProvider);
    final activeTag = _query.toLowerCase().replaceFirst('#', '');

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: ArtoraBottomNav(
        currentIndex: null,
        onSelected: (index) => context.go(ArtoraBottomNav.tabPaths[index]),
        onCreate: ArtoraBottomNav.showCreateComingSoon,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _close,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: Icon(
                      AppIcons.back,
                      color: colors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: _SearchInput(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.initialQuery.isEmpty,
                      onChanged: _onChanged,
                      onSubmitted: _submit,
                      onClear: _clear,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clear();
                      _focusNode.unfocus();
                    },
                    child: Text(
                      LocaleKeys.discover_cancel.tr(),
                      style: context.textTheme.titleSmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              labelStyle: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: colors.primary,
              indicatorWeight: 3.r,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: colors.outlineVariant,
              dividerHeight: 1,
              onTap: (index) =>
                  setState(() => _scope = SearchScope.values[index]),
              tabs: [
                Tab(text: LocaleKeys.discover_all.tr()),
                Tab(text: LocaleKeys.discover_artwork.tr()),
                Tab(text: LocaleKeys.discover_artists.tr()),
                Tab(text: LocaleKeys.discover_tags.tr()),
                Tab(text: LocaleKeys.profile_collections.tr()),
              ],
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  top: AppSpacing.sm,
                  // Clear the floating bottom nav (the body extends under it).
                  bottom: MediaQuery.paddingOf(context).bottom + 110.r,
                ),
                children: [
                  if (recent.isNotEmpty) ...[
                    SectionHeader(
                      title: LocaleKeys.discover_recent_searches.tr(),
                      actionLabel: LocaleKeys.discover_clear_all.tr(),
                      onAction: () =>
                          ref.read(recentSearchesProvider.notifier).clear(),
                    ),
                    for (final entry in recent.take(_visibleRecent))
                      _RecentSearchRow(
                        query: entry,
                        onTap: () => _submit(entry),
                        onRemove: () => ref
                            .read(recentSearchesProvider.notifier)
                            .remove(entry),
                      ),
                    AppSpacing.vGap(AppSpacing.sm),
                  ],
                  SectionHeader(title: LocaleKeys.discover_trending_tags.tr()),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: switch (trending) {
                      RequestSuccess(:final data) => Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final tag in data)
                              SelectablePill(
                                label: '#$tag',
                                selected: activeTag == tag,
                                onTap: () => _submit(tag),
                              ),
                          ],
                        ),
                      RequestFailure() => const SizedBox.shrink(),
                      RequestInitial() || RequestLoading() => SizedBox(
                          height: 40.h,
                        ),
                    },
                  ),
                  if (_query.isNotEmpty) ...[
                    AppSpacing.vGap(AppSpacing.md),
                    SectionHeader(title: LocaleKeys.discover_results.tr()),
                    _buildResults(results),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(RequestState<SearchResults> results) {
    final pagePadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.pagePadding,
    );

    return switch (results) {
      RequestInitial() || RequestLoading() => Padding(
          padding: pagePadding.copyWith(top: AppSpacing.sm),
          child: const MasonrySkeleton(),
        ),
      RequestFailure() => AppErrorPresets.network(
          onRetry: () => _submit(_query),
        ),
      RequestSuccess(:final data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_scope == SearchScope.all)
              TabBar(
                controller: _resultTabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                labelColor: context.colors.primary,
                unselectedLabelColor: context.colors.onSurfaceVariant,
                labelStyle: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: context.colors.primary,
                indicatorWeight: 3.r,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: context.colors.outlineVariant,
                dividerHeight: 1,
                onTap: (index) => setState(
                  () => _resultTab = SearchScope.values[index + 1],
                ),
                tabs: [
                  Tab(
                    text: _countLabel(
                      LocaleKeys.discover_artwork,
                      data.artworks.length,
                    ),
                  ),
                  Tab(
                    text: _countLabel(
                      LocaleKeys.discover_artists,
                      data.artists.length,
                    ),
                  ),
                  Tab(
                    text: _countLabel(
                      LocaleKeys.discover_tags,
                      data.tags.length,
                    ),
                  ),
                  Tab(
                    text: _countLabel(
                      LocaleKeys.profile_collections,
                      data.collections.length,
                    ),
                  ),
                ],
              ),
            AppSpacing.vGap(AppSpacing.md),
            _ResultsBody(
              results: data,
              type: _scope == SearchScope.all ? _resultTab : _scope,
              onTag: _submit,
            ),
          ],
        ),
    };
  }

  String _countLabel(String labelKey, int count) =>
      LocaleKeys.discover_result_count.tr(
        namedArgs: {'label': labelKey.tr(), 'count': '$count'},
      );
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({
    required this.results,
    required this.type,
    required this.onTag,
  });

  final SearchResults results;
  final SearchScope type;
  final ValueChanged<String> onTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagePadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.pagePadding,
    );
    final noResults = AppEmptyPresets.noResults(
      onExplore: () => context.go(AppRoutes.explore),
    );

    switch (type) {
      case SearchScope.artists:
        if (results.artists.isEmpty) return noResults;
        final following = ref.watch(followingProvider);
        final pending = ref.watch(followPendingProvider);
        final blocked = ref.watch(blockedIdsProvider);
        return Column(
          children: [
            for (final artist in results.artists)
              AppArtistRow(
                name: artist.displayName,
                handle: '@${artist.username}',
                avatarUrl: artist.avatarUrl,
                bio: LocaleKeys.discover_followers.tr(
                  namedArgs: {'count': formatCompact(artist.followers)},
                ),
                isFollowing: artist.id == AppConfig.supabase.auth.currentUser?.id
                    ? null
                    : following.contains(artist.id),
                isFollowLoading: pending.contains(artist.id),
                onTap: () =>
                    context.push(AppRoutes.artistProfilePath(artist.id)),
                onFollow: () =>
                    ref.read(followActionsProvider).toggle(artist.id),
                isBlocked: blocked.contains(artist.id),
                onUnblock: () => unblockWithToast(ref, artist.id),
              ),
          ],
        );
      case SearchScope.tags:
        if (results.tags.isEmpty) return noResults;
        return Padding(
          padding: pagePadding,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in results.tags)
                SelectablePill(label: '#$tag', onTap: () => onTag(tag)),
            ],
          ),
        );
      case SearchScope.collections:
        if (results.collections.isEmpty) return noResults;
        return Padding(
          padding: pagePadding,
          child: Column(
            children: [
              for (final c in results.collections)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.ms),
                  // shortcut: no collection detail screen yet, so open the owner.
                  child: AppCollectionCard(
                    title: c.title,
                    subtitle: LocaleKeys.collection_artwork_count.tr(
                      namedArgs: {'count': formatCompact(c.artworkCount)},
                    ),
                    imageUrl: c.coverUrl,
                    onTap: c.ownerId == null
                        ? null
                        : () => context.push(
                              AppRoutes.artistProfilePath(c.ownerId!),
                            ),
                  ),
                ),
            ],
          ),
        );
      case SearchScope.all || SearchScope.artwork:
        if (results.artworks.isEmpty) return noResults;
        return Padding(
          padding: pagePadding,
          child: ArtworkMasonry(artworks: results.artworks),
        );
    }
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppBorders.md,
          borderSide: BorderSide(color: color),
        );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      cursorColor: colors.primary,
      style: context.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        hintText: LocaleKeys.discover_search_hint_explore.tr(),
        contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.ms),
        prefixIcon: Icon(AppIcons.search, color: colors.onSurfaceVariant),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: LocaleKeys.discover_clear_search.tr(),
                icon: Icon(
                  AppIcons.cancelFilled,
                  size: 20.r,
                  color: colors.onSurfaceVariant,
                ),
              ),
        enabledBorder: border(colors.outline),
        focusedBorder: border(colors.primary),
        border: border(colors.outline),
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pagePadding,
          right: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.history,
              size: 20.r,
              color: colors.onSurfaceVariant,
            ),
            AppSpacing.hGap(AppSpacing.ms),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: Icon(
                AppIcons.close,
                size: 20.r,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
