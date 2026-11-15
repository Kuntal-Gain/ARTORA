import 'dart:async';

import 'package:artora/src/features/discover/data/discover_usecase.dart';
import 'package:artora/src/features/discover/data/discover_usecase_impl.dart';
import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/imports/imports.dart';

// ── USECASE ─────────────────────────────────────────────────

final discoverUsecaseProvider = Provider<DiscoverUsecase>(
  (ref) => DiscoverUsecaseImpl(),
);

// ── GENERIC FETCH NOTIFIER ──────────────────────────────────

typedef DiscoverLoader<T> = Future<Resource<T>> Function();

/// Handles loading, refreshing, success and failure for
/// any discover GET operation.
///
/// Automatically fetches when the provider is first watched.
class DiscoverFetchNotifier<T> extends StateNotifier<RequestState<T>> {
  DiscoverFetchNotifier(this._loader) : super(const RequestInitial()) {
    unawaited(Future.microtask(fetch));
  }

  final DiscoverLoader<T> _loader;

  int _requestId = 0;

  Future<void> fetch() async {
    if (!mounted) return;

    final requestId = ++_requestId;

    state = const RequestLoading();

    final result = await _loader();

    if (!mounted || requestId != _requestId) return;

    state = result.toRequestState();
  }

  Future<void> refresh() => fetch();
}

// ── PUBLIC FEED ─────────────────────────────────────────────

final publicArtworkFeedProvider = StateNotifierProvider.autoDispose<
    DiscoverFetchNotifier<ArtworkListModel>, RequestState<ArtworkListModel>>(
  (ref) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return DiscoverFetchNotifier(
      usecase.getPublicFeed,
    );
  },
);

// ── USER FEED ───────────────────────────────────────────────

final userArtworkFeedProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<ArtworkListModel>,
    RequestState<ArtworkListModel>,
    String>(
  (ref, uid) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return DiscoverFetchNotifier(
      () => usecase.getUserFeed(uid),
    );
  },
);

// ── USER LIKED ARTWORKS ─────────────────────────────────────

final userLikedArtworksProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<ArtworkListModel>,
    RequestState<ArtworkListModel>,
    String>(
  (ref, uid) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return DiscoverFetchNotifier(
      () => usecase.getUserLikedArtworks(uid),
    );
  },
);


// ── TOGGLE ARTWORK LIKE ─────────────────────────────────────


final toggleArtworkLikeProvider = StateNotifierProvider.autoDispose
    .family<ArtworkActionNotifier, RequestState<void>, String>(
  (ref, artworkId) {
    final usecase = ref.read(discoverUsecaseProvider);

    return ArtworkActionNotifier(
      () => usecase.toggleLike(artworkId),
      onSuccess: () {
        // Actual providers used by HomeFeedScreen.
        ref.invalidate(feedProvider);
        ref.invalidate(followingFeedProvider);

        // Other discover feeds.
        ref.invalidate(publicArtworkFeedProvider);
        ref.invalidate(userArtworkFeedProvider);
        ref.invalidate(userLikedArtworksProvider);
        ref.invalidate(userSavedArtworksProvider);

        // Artwork details.
        ref.invalidate(singleArtworkProvider(artworkId));
      },
    );
  },
);


// ── USER SAVED ARTWORKS ─────────────────────────────────────

final userSavedArtworksProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<ArtworkListModel>,
    RequestState<ArtworkListModel>,
    String>(
  (ref, uid) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return DiscoverFetchNotifier(
      () => usecase.getUserSavedArtworks(uid),
    );
  },
);

// ── SINGLE ARTWORK ──────────────────────────────────────────

final singleArtworkProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<ArtworkModel>, RequestState<ArtworkModel>, String>(
  (ref, postId) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return DiscoverFetchNotifier(
      () => usecase.getSinglePost(postId),
    );
  },
);

// ── ARTWORK DETAIL (WITH ARTIST) ────────────────────────────

final artworkDetailProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<ArtworkModel>, RequestState<ArtworkModel>, String>(
  (ref, postId) => DiscoverFetchNotifier(
    () => ref.watch(discoverUsecaseProvider).fetchPostById(postId),
  ),
);

// ── POST ARTWORK NOTIFIER ───────────────────────────────────

class PostArtworkNotifier extends StateNotifier<RequestState<void>> {
  PostArtworkNotifier(
    this._send, {
    required void Function() onSuccess,
  })  : _onSuccess = onSuccess,
        super(const RequestInitial());

  /// Create or update, depending on the provider.
  final Future<Resource<void>> Function(PostArtworkModel) _send;
  final void Function() _onSuccess;

  bool _isSubmitting = false;

  Future<void> submit(PostArtworkModel artwork) async {
    if (!mounted || _isSubmitting) return;

    _isSubmitting = true;
    state = const RequestLoading();

    try {
      final result = await _send(artwork);

      if (!mounted) return;

      state = result.toRequestState();

      if (result is ResourceSuccess<void>) {
        _onSuccess();
      }
    } finally {
      _isSubmitting = false;
    }
  }

  void reset() {
    if (!mounted) return;
    state = const RequestInitial();
  }
}

// ── POST ARTWORK PROVIDER ───────────────────────────────────

final postArtworkProvider =
    StateNotifierProvider.autoDispose<PostArtworkNotifier, RequestState<void>>(
  (ref) {
    return PostArtworkNotifier(
      ref.watch(discoverUsecaseProvider).postArtwork,
      onSuccess: () {
        ref.invalidate(publicArtworkFeedProvider);
        ref.invalidate(userArtworkFeedProvider);
      },
    );
  },
);

// ── UPDATE ARTWORK ──────────────────────────────────────────

final updateArtworkProvider = StateNotifierProvider.autoDispose
    .family<PostArtworkNotifier, RequestState<void>, String>(
  (ref, artworkId) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return PostArtworkNotifier(
      (artwork) => usecase.updateArtwork(artworkId, artwork),
      onSuccess: () {
        ref.invalidate(publicArtworkFeedProvider);
        ref.invalidate(userArtworkFeedProvider);
        ref.invalidate(singleArtworkProvider(artworkId));
        ref.invalidate(artworkDetailProvider(artworkId));
      },
    );
  },
);

// ── CATEGORIES ──────────────────────────────────────────────

// Not autoDispose: categories rarely change, so fetch once and keep in memory.
final artworkCategoriesProvider = StateNotifierProvider<
    DiscoverFetchNotifier<List<ArtworkCategoryModel>>,
    RequestState<List<ArtworkCategoryModel>>>(
  (ref) => DiscoverFetchNotifier(
    ref.watch(discoverUsecaseProvider).getCategories,
  ),
);

// ── GENERIC ARTWORK ACTION NOTIFIER ─────────────────────────

typedef ArtworkAction = Future<Resource<void>> Function();

/// Shared state management for delete, like and save.
///
/// Each artwork gets its own action state through
/// the corresponding family provider.
class ArtworkActionNotifier extends StateNotifier<RequestState<void>> {
  ArtworkActionNotifier(
    this._action, {
    required void Function() onSuccess,
  })  : _onSuccess = onSuccess,
        super(const RequestInitial());

  final ArtworkAction _action;
  final void Function() _onSuccess;

  bool _isSubmitting = false;

  Future<void> submit() async {
    if (!mounted || _isSubmitting) return;

    _isSubmitting = true;
    state = const RequestLoading();

    try {
      final result = await _action();

      if (!mounted) return;

      state = result.toRequestState();

      if (result is ResourceSuccess<void>) {
        _onSuccess();
      }
    } finally {
      _isSubmitting = false;
    }
  }

  void reset() {
    if (!mounted) return;
    state = const RequestInitial();
  }
}

// ── DELETE ARTWORK ──────────────────────────────────────────

final deleteArtworkProvider = StateNotifierProvider.autoDispose
    .family<ArtworkActionNotifier, RequestState<void>, String>(
  (ref, artworkId) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return ArtworkActionNotifier(
      () => usecase.deleteArtwork(artworkId),
      onSuccess: () {
        ref.invalidate(publicArtworkFeedProvider);
        ref.invalidate(userArtworkFeedProvider);
        ref.invalidate(userLikedArtworksProvider);
        ref.invalidate(userSavedArtworksProvider);
        ref.invalidate(singleArtworkProvider(artworkId));
      },
    );
  },
);


// ── TOGGLE ARTWORK SAVE ─────────────────────────────────────

final toggleArtworkSaveProvider = StateNotifierProvider.autoDispose
    .family<ArtworkActionNotifier, RequestState<void>, String>(
  (ref, artworkId) {
    final usecase = ref.watch(discoverUsecaseProvider);

    return ArtworkActionNotifier(
      () => usecase.toggleSave(artworkId),
      onSuccess: () {
        ref.invalidate(publicArtworkFeedProvider);
        ref.invalidate(userArtworkFeedProvider);
        ref.invalidate(userSavedArtworksProvider);
        ref.invalidate(singleArtworkProvider(artworkId));
      },
    );
  },
);
