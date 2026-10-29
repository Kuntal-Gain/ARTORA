import 'dart:async';

import 'package:artora/src/features/discover/data/discover_repository.dart';
import 'package:artora/src/features/discover/data/recent_search_store.dart';
import 'package:artora/src/features/discover/data/sample_discover_repository.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/imports/imports.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => SampleDiscoverRepository(),
);

/// Loads on creation. [refresh] keeps showing the last data while reloading,
/// so pull-to-refresh doesn't flash a skeleton.
class LoadNotifier<T> extends StateNotifier<RequestState<T>> {
  LoadNotifier(this._load) : super(const RequestLoading()) {
    refresh();
  }

  final Future<Resource<T>> Function() _load;

  Future<void> refresh() async {
    if (state is! RequestSuccess<T>) state = const RequestLoading();
    final result = await _load();
    if (!mounted) return;
    state = result.toRequestState();
  }
}

/// Optimistic on/off set (follows, likes, bookmarks). The change shows
/// immediately and is rolled back if the repository rejects it.
class ToggleSetNotifier extends StateNotifier<Set<String>> {
  ToggleSetNotifier(
    this._persist, {
    Future<Resource<Set<String>>> Function()? load,
  }) : super(const <String>{}) {
    if (load != null) _seed(load);
  }

  final Future<Resource<void>> Function(String id, bool on) _persist;

  Future<void> _seed(Future<Resource<Set<String>>> Function() load) async {
    final result = await load();
    if (!mounted) return;
    final ids = result.dataOrNull;
    if (ids != null) state = {...ids, ...state};
  }

  Future<void> toggle(String id) async {
    final on = !state.contains(id);
    _set(id, on);
    final result = await _persist(id, on);
    if (!mounted) return;
    if (result case ResourceError<void>(:final failure)) {
      _set(id, !on);
      showGlobalToast(message: failure.message, status: 'error');
    }
  }

  void _set(String id, bool on) =>
      state = on ? {...state, id} : ({...state}..remove(id));
}

class SearchNotifier extends StateNotifier<RequestState<SearchResults>> {
  SearchNotifier(this._repository) : super(const RequestInitial());

  static const Duration _debounce = Duration(milliseconds: 300);

  final DiscoverRepository _repository;
  Timer? _timer;
  String _latest = '';

  /// Debounced while typing; pass [immediate] for submits and tapped
  /// suggestions.
  void search(String raw, {bool immediate = false}) {
    final query = raw.trim();
    _latest = query;
    _timer?.cancel();

    if (query.isEmpty) {
      state = const RequestInitial();
      return;
    }
    // Keep the previous results on screen while the next query runs.
    if (state is! RequestSuccess<SearchResults>) state = const RequestLoading();
    if (immediate) {
      _run(query);
    } else {
      _timer = Timer(_debounce, () => _run(query));
    }
  }

  Future<void> _run(String query) async {
    final result = await _repository.search(query);
    if (!mounted || query != _latest) return;
    state = result.toRequestState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(RecentSearchStore store)
    : _store = store,
      super(store.read());

  final RecentSearchStore _store;

  void add(String raw) {
    final query = raw.trim();
    if (query.isEmpty) return;
    _save([
      query,
      ...state.where((entry) => entry.toLowerCase() != query.toLowerCase()),
    ].take(RecentSearchStore.maxEntries).toList());
  }

  void remove(String query) =>
      _save(state.where((entry) => entry != query).toList());

  void clear() => _save(const []);

  void _save(List<String> entries) {
    state = entries;
    _store.write(entries);
  }
}

final currentArtistProvider =
    StateNotifierProvider<LoadNotifier<Artist>, RequestState<Artist>>(
      (ref) => LoadNotifier(ref.watch(discoverRepositoryProvider).currentArtist),
    );

final feedProvider =
    StateNotifierProvider<
      LoadNotifier<List<Artwork>>,
      RequestState<List<Artwork>>
    >((ref) => LoadNotifier(ref.watch(discoverRepositoryProvider).feed));

final exploreProvider =
    StateNotifierProvider<
      LoadNotifier<ExploreContent>,
      RequestState<ExploreContent>
    >((ref) => LoadNotifier(ref.watch(discoverRepositoryProvider).explore));

final trendingTagsProvider =
    StateNotifierProvider<LoadNotifier<List<String>>, RequestState<List<String>>>(
      (ref) =>
          LoadNotifier(ref.watch(discoverRepositoryProvider).trendingTags),
    );

final followingProvider =
    StateNotifierProvider<ToggleSetNotifier, Set<String>>((ref) {
      final repository = ref.watch(discoverRepositoryProvider);
      return ToggleSetNotifier(
        (id, on) => repository.setFollowing(id, following: on),
        load: repository.followingIds,
      );
    });

final likedProvider = StateNotifierProvider<ToggleSetNotifier, Set<String>>((
  ref,
) {
  final repository = ref.watch(discoverRepositoryProvider);
  return ToggleSetNotifier((id, on) => repository.setLiked(id, liked: on));
});

final bookmarkedProvider =
    StateNotifierProvider<ToggleSetNotifier, Set<String>>((ref) {
      final repository = ref.watch(discoverRepositoryProvider);
      return ToggleSetNotifier(
        (id, on) => repository.setBookmarked(id, bookmarked: on),
      );
    });

/// Feed narrowed to artists the user follows ("Following" tab).
final followingFeedProvider = Provider<RequestState<List<Artwork>>>((ref) {
  final feed = ref.watch(feedProvider);
  final following = ref.watch(followingProvider);
  return switch (feed) {
    RequestSuccess(:final data) => RequestSuccess(
      data.where((artwork) => following.contains(artwork.artist.id)).toList(),
    ),
    _ => feed,
  };
});

final savedArtworksProvider = Provider<RequestState<List<Artwork>>>((ref) {
  final feed = ref.watch(feedProvider);
  final bookmarked = ref.watch(bookmarkedProvider);
  return switch (feed) {
    RequestSuccess(:final data) => RequestSuccess(
      data.where((artwork) => bookmarked.contains(artwork.id)).toList(),
    ),
    _ => feed,
  };
});

/// Category picked in the explore chip row; `null` means "All".
final exploreCategoryProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Explore content with artists and editor's picks narrowed to the selected
/// category.
final filteredExploreProvider =
    Provider.autoDispose<RequestState<ExploreContent>>((ref) {
      final explore = ref.watch(exploreProvider);
      final category = ref.watch(exploreCategoryProvider);
      if (category == null) return explore;
      return switch (explore) {
        RequestSuccess(:final data) => RequestSuccess((
          categories: data.categories,
          trendingTags: data.trendingTags,
          collections: data.collections,
          artists: data.artists
              .where((artist) => artist.specialties.contains(category))
              .toList(),
          editorsPicks: data.editorsPicks
              .where((artwork) => artwork.category == category)
              .toList(),
        )),
        _ => explore,
      };
    });

final searchProvider =
    StateNotifierProvider.autoDispose<
      SearchNotifier,
      RequestState<SearchResults>
    >((ref) => SearchNotifier(ref.watch(discoverRepositoryProvider)));

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
      (ref) => RecentSearchesNotifier(RecentSearchStore()),
    );
