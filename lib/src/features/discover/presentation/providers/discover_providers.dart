import 'dart:async';

import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/discover/data/discover_usecase.dart';
import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
import 'package:artora/src/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgresChangeEvent;
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/imports/imports.dart';

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

  /// Applies [change] to loaded data; ignored until the first load succeeds.
  void mutate(T Function(T data) change) {
    if (state case RequestSuccess<T>(:final data)) {
      state = RequestSuccess(change(data));
    }
  }
}

/// Optimistic on/off set (follows, likes, bookmarks). The change shows
/// immediately and is rolled back if the repository rejects it.
class ToggleSetNotifier extends StateNotifier<Set<String>> {
  ToggleSetNotifier(
    this._persist, {
    Future<Resource<Set<String>>> Function()? load,
  })  : _load = load,
        super(const <String>{}) {
    if (load != null) _seed(load);
  }

  final Future<Resource<Set<String>>> Function()? _load;

  /// Replaces the set with the server's, e.g. after a change made elsewhere.
  Future<void> reload() async {
    final ids = (await _load?.call())?.dataOrNull;
    if (mounted && ids != null) state = ids;
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
  SearchNotifier(this._usecase) : super(const RequestInitial());

  static const Duration _debounce = Duration(milliseconds: 300);

  final DiscoverUsecase _usecase;
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
    final result = await _usecase.search(query);
    if (!mounted || query != _latest) return;
    state = result.toRequestState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Recent search queries, persisted through [StorageService].
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier()
      : super(
          StorageService.instance.getStringList(StorageKeys.recentSearches) ??
              const <String>[],
        );

  static const int maxEntries = 10;

  void add(String raw) {
    final query = raw.trim();
    if (query.isEmpty) return;
    _save([
      query,
      ...state.where((entry) => entry.toLowerCase() != query.toLowerCase()),
    ].take(maxEntries).toList());
  }

  void remove(String query) =>
      _save(state.where((entry) => entry != query).toList());

  void clear() => _save(const []);

  void _save(List<String> entries) {
    state = entries;
    // Failures come back as values and are logged by StorageService; a lost
    // recent-search list isn't worth interrupting the user.
    unawaited(
      StorageService.instance.setStringList(
        StorageKeys.recentSearches,
        entries,
      ),
    );
  }
}

/// The signed-in user, shaped as an [Artist] for the top bar.
final currentArtistProvider =
    StateNotifierProvider<LoadNotifier<Artist>, RequestState<Artist>>((ref) {
  final auth = ref.watch(authUsecaseProvider);
  return LoadNotifier(() async {
    final result = await auth.getUser();
    return result.map(
      (user) => Artist(
        id: user.id,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: SupabaseStorageService.instance.publicUrl(
              SupabaseBuckets.avatars,
              user.avatarPath,
            ) ??
            '',
      ),
    );
  });
});

// ═══════════════════════════════════════════════════════════
// FEED — home feed ("For You" / "Following") and saved
// ═══════════════════════════════════════════════════════════

/// The API's artwork has no image size yet, so the aspect ratio falls back to
/// a neutral value. The artist comes from the embedded `profile`; if that is
/// missing the artist row stays blank.
Artwork _toArtwork(ArtworkModel model) {
  final image = model.images.isEmpty ? null : model.images.first;
  final profile = model.artist;
  return Artwork(
    id: model.id,
    title: model.title,
    imageUrl: image?.thumbnailUrl ?? image?.url ?? '',
    aspectRatio: 1,
    artist: Artist(
      id: model.userId,
      username: profile?.username ?? '',
      displayName: profile?.displayName ?? '',
      avatarUrl: profile?.avatarUrl ?? '',
      specialties: profile?.specialties ?? const [],
    ),
    category: model.category?.name ?? '',
    tags: model.tags,
    likes: model.likesCount,
    comments: model.commentsCount,
  );
}

/// Heart and count update instantly; the realtime echo is then ignored.
Future<void> toggleLikeOptimistic(WidgetRef ref, String id) async {
  final delta = ref.read(likedProvider).contains(id) ? -1 : 1;
  void apply(int d) => ref.read(feedProvider.notifier).mutate((list) => [
        for (final a in list) a.id == id ? a.withLikes(a.likes + d) : a,
      ]);
  apply(delta);
  await ref.read(likedProvider.notifier).toggle(id);
  // toggle() rolls the heart back on failure; undo the count to match.
  if (ref.read(likedProvider).contains(id) != (delta > 0)) {
    apply(-delta);
  }
}

final feedProvider = StateNotifierProvider<LoadNotifier<List<Artwork>>,
    RequestState<List<Artwork>>>((ref) {
  final usecase = ref.watch(discoverUsecaseProvider);
  final notifier = LoadNotifier<List<Artwork>>(() async {
    final result = await usecase.getPublicFeed();
    return result.map((list) => list.artworks.map(_toArtwork).toList());
  });

  // Live like counts. Needs `likes` in the supabase_realtime publication
  // (and REPLICA IDENTITY FULL so DELETE payloads carry artwork_id).
  void bump(String? id, int delta) {
    if (id == null) return;
    notifier.mutate((list) => [
          for (final a in list) a.id == id ? a.withLikes(a.likes + delta) : a,
        ]);
  }

  final channel = SBClient.instance.subscribeChanges(
    'likes',
    event: PostgresChangeEvent.all,
    // debugPrint, not AppLogger: developer.log doesn't show in `flutter run`.
    onStatus: (status, error) =>
        debugPrint('[REALTIME] likes status: $status $error'),
    onChange: (p) {
      debugPrint(
        '[REALTIME] likes ${p.eventType.name} old=${p.oldRecord} new=${p.newRecord}',
      );
      // Our own likes are already counted optimistically; ignore their echo.
      final me = AppConfig.supabase.auth.currentUser?.id;
      switch (p.eventType) {
        case PostgresChangeEvent.insert:
          if (p.newRecord['user_id'] == me) return;
          bump(p.newRecord['artwork_id'] as String?, 1);
        case PostgresChangeEvent.delete:
          if (p.oldRecord['user_id'] == me) return;
          final id = p.oldRecord['artwork_id'] as String?;
          // Without REPLICA IDENTITY FULL the payload only has the row's
          // primary key, so fall back to a reload.
          if (id == null) {
            notifier.refresh();
          } else {
            bump(id, -1);
          }
          // The heart state is per-user and the payload can't say whose
          // like it was, so re-sync it.
          ref.read(likedProvider.notifier).reload();
        default:
      }
    },
  );
  ref.onDispose(() => SBClient.instance.unsubscribeChanges(channel));
  return notifier;
});

// ═══════════════════════════════════════════════════════════
// EXPLORE — categories, trending tags, collections, artists, picks
// ═══════════════════════════════════════════════════════════

/// Live data from the `get_explore` function (supabase/explore.sql).
final exploreProvider = StateNotifierProvider<LoadNotifier<ExploreContent>,
    RequestState<ExploreContent>>((ref) {
  final usecase = ref.watch(discoverUsecaseProvider);
  return LoadNotifier(() => usecase.fetchExplore());
});

/// Trending tags are part of the explore data, so search reuses them.
final trendingTagsProvider = Provider<RequestState<List<String>>>((ref) {
  return switch (ref.watch(exploreProvider)) {
    RequestSuccess(:final data) => RequestSuccess(data.trendingTags),
    RequestFailure(:final failure) => RequestFailure(failure),
    RequestLoading() => const RequestLoading(),
    RequestInitial() => const RequestInitial(),
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

// ═══════════════════════════════════════════════════════════
// SHARED — likes and bookmarks, used by feed and explore (follows are in
// state/follow_provider.dart)
// ═══════════════════════════════════════════════════════════

/// Ids in the public feed matching [test], used to seed like / save state.
Future<Resource<Set<String>>> _feedIds(
  DiscoverUsecase usecase,
  bool Function(ArtworkModel) test,
) async {
  final result = await usecase.getPublicFeed();
  return result.map(
    (list) => list.artworks.where(test).map((a) => a.id).toSet(),
  );
}

// The server flips the state, so [on] is unused.
final likedProvider = StateNotifierProvider<ToggleSetNotifier, Set<String>>((
  ref,
) {
  final usecase = ref.watch(discoverUsecaseProvider);
  return ToggleSetNotifier(
    (id, on) => usecase.toggleLike(id),
    load: () => _feedIds(usecase, (a) => a.isLiked),
  );
});

final bookmarkedProvider =
    StateNotifierProvider<ToggleSetNotifier, Set<String>>((ref) {
  final usecase = ref.watch(discoverUsecaseProvider);
  return ToggleSetNotifier(
    (id, on) => usecase.toggleSave(id),
    load: () => _feedIds(usecase, (a) => a.isBookmarked),
  );
});

// ── FEED (derived from feedProvider) ──────────────────────

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

// ═══════════════════════════════════════════════════════════
// SEARCH
// ═══════════════════════════════════════════════════════════

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier,
        RequestState<SearchResults>>(
    (ref) => SearchNotifier(ref.watch(discoverUsecaseProvider)));

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) => RecentSearchesNotifier(),
);
