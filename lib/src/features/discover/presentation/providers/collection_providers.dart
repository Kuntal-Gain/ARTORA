import 'dart:io';

import 'package:artora/src/features/discover/model/collection_model.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/imports/imports.dart';

// Collections (needs supabase/collections.sql).

/// Collections owned by a user; private ones only come back for yourself.
final userCollectionsProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<List<CollectionModel>>,
    RequestState<List<CollectionModel>>,
    String>(
  (ref, userId) {
    final usecase = ref.watch(discoverUsecaseProvider);
    return DiscoverFetchNotifier(() => usecase.getUserCollections(userId));
  },
);

/// Public collections with the most recent likes and saves (Explore tab).
final trendingCollectionsProvider = StateNotifierProvider.autoDispose<
    DiscoverFetchNotifier<List<CollectionModel>>,
    RequestState<List<CollectionModel>>>(
  (ref) => DiscoverFetchNotifier(
    ref.watch(discoverUsecaseProvider).getTrendingCollections,
  ),
);

/// Creates a collection; success carries the new collection's id.
class CreateCollectionNotifier extends StateNotifier<RequestState<String>> {
  CreateCollectionNotifier(this._ref) : super(const RequestInitial());

  final Ref _ref;

  Future<void> submit({
    required String title,
    File? cover,
    List<String> artworkIds = const [],
  }) async {
    if (state is RequestLoading) return;
    state = const RequestLoading();
    final result = await _ref.read(discoverUsecaseProvider).createCollection(
          title,
          cover: cover,
          artworkIds: artworkIds,
          // No visibility toggle in the design; collections are made to share.
          isPublic: true,
        );
    if (!mounted) return;
    state = result.toRequestState();
    if (result is ResourceSuccess<String>) {
      _ref
        ..invalidate(userCollectionsProvider)
        ..invalidate(trendingCollectionsProvider);
    }
  }
}

final createCollectionProvider = StateNotifierProvider.autoDispose<
    CreateCollectionNotifier, RequestState<String>>(
  CreateCollectionNotifier.new,
);
