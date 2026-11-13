import 'package:artora/src/features/discover/data/discover_helper.dart';
import 'package:artora/src/features/discover/data/discover_usecase.dart';
import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/network/client/sb_client.dart';
import 'package:artora/src/network/constants/supabase_tables.dart';
import 'package:artora/src/network/failures/failure.dart';
import 'package:artora/src/network/resource/resource.dart';

/// The discover operations. Only the contract's methods live here; queries and
/// row mapping are in [DiscoverHelper].
class DiscoverUsecaseImpl implements DiscoverUsecase {
  final _h = const DiscoverHelper();

  // ── GET PUBLIC FEED ──────────────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getPublicFeed() {
    return _h.getArtworkPage(
      eq: {'visibility': 'public'},
    );
  }

  // ── SEARCH ───────────────────────────────────────────────

  @override
  Future<Resource<SearchResults>> search(String query) => _h.search(query);

  // ── FOLLOWS ──────────────────────────────────────────────
  // Needs the `follows` table (supabase/explore.sql).

  @override
  Future<Resource<Set<String>>> getFollowingIds() async {
    final auth = await _h.authUserId();
    if (auth case ResourceError<String>(:final failure)) {
      return Resource<Set<String>>.error(failure);
    }
    final result = await _h.db.get(
      SupabaseTables.follows,
      columns: 'following_id',
      eq: {'follower_id': (auth as ResourceSuccess<String>).data},
    );
    return result.map(
      (rows) =>
          rows.map((r) => r['following_id']).whereType<String>().toSet(),
    );
  }

  @override
  Future<Resource<void>> setFollowing(
    String artistId, {
    required bool following,
  }) async {
    final auth = await _h.authUserId();
    if (auth case ResourceError<String>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final uid = (auth as ResourceSuccess<String>).data;
    if (uid == artistId) {
      return const Resource<void>.error(
        ValidationFailure('You cannot follow yourself.'),
      );
    }
    final row = <String, Object?>{
      'follower_id': uid,
      'following_id': artistId,
    };
    final result = following
        ? await _h.db.put(
            SupabaseTables.follows,
            row,
            onConflict: 'follower_id,following_id',
          )
        : await _h.db.delete(SupabaseTables.follows, eq: row);
    return result.map<void>((_) {});
  }

  // ── GET USER FEED ────────────────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getUserFeed(
    String uid,
  ) async {
    final viewerId = await _h.viewerId();

    return _h.getArtworkPage(
      eq: {
        'user_id': uid,
        if (viewerId != uid) 'visibility': 'public',
      },
    );
  }

  // ── GET SINGLE ARTWORK ───────────────────────────────────

  @override
  Future<Resource<ArtworkModel>> getSinglePost(
    String postId,
  ) async {
    final result = await _h.db.getOne(
      SupabaseTables.artworks,
      columns: DiscoverHelper.artworkColumns,
      eq: {'id': postId},
    );

    return switch (result) {
      ResourceSuccess<SBRow>(:final data) =>
        (await _h.attachViewerState([data])).map(
          (rows) => ArtworkModel.fromJson(rows.first),
        ),
      ResourceError<SBRow>(:final failure) =>
        Resource<ArtworkModel>.error(failure),
      ResourceLoading<SBRow>() => const Resource<ArtworkModel>.loading(),
    };
  }

  /// Two queries, not an embedded join: PostgREST can only embed `profiles`
  /// when `artworks.user_id` has a foreign key to it, and ours doesn't.
  @override
  Future<Resource<ArtworkModel>> fetchPostById(String postId) async {
    final result = await _h.db.getOne(
      SupabaseTables.artworks,
      columns: DiscoverHelper.artworkColumns,
      eq: {'id': postId},
    );

    return switch (result) {
      ResourceSuccess<SBRow>(:final data) => _h.withProfile(data),
      ResourceError<SBRow>(:final failure) =>
        Resource<ArtworkModel>.error(failure),
      ResourceLoading<SBRow>() => const Resource<ArtworkModel>.loading(),
    };
  }

  // shortcut: first 20 only, no paging; add a cursor when threads get long.
  @override
  Future<Resource<List<CommentModel>>> fetchComments(
    String artworkId, {
    bool newestFirst = true,
  }) async {
    final result = await _h.db.get(
      SupabaseTables.comments,
      columns: DiscoverHelper.commentColumns,
      eq: {'artwork_id': artworkId},
      filter: (query) => query.isFilter('parent_id', null),
      orderBy: 'created_at',
      ascending: !newestFirst,
      limit: DiscoverHelper.pageSize,
    );
    return _h.toComments(await _h.withReplyCounts(result));
  }

  @override
  Future<Resource<List<CommentModel>>> fetchReplies(String commentId) async {
    final result = await _h.db.get(
      SupabaseTables.comments,
      columns: DiscoverHelper.commentColumns,
      eq: {'parent_id': commentId},
      orderBy: 'created_at',
    );
    return _h.toComments(result);
  }

  @override
  Future<Resource<void>> toggleCommentLike(String commentId) async {
    final auth = await _h.authUserId();
    if (auth case ResourceError<String>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final eq = <String, Object?>{
      'comment_id': commentId,
      'user_id': (auth as ResourceSuccess<String>).data,
    };
    final existing = await _h.db.get(
      DiscoverHelper.commentLikesTable,
      columns: 'comment_id',
      eq: eq,
      limit: 1,
    );
    return switch (existing) {
      ResourceSuccess<List<SBRow>>(:final data) when data.isNotEmpty =>
        (await _h.db.delete(DiscoverHelper.commentLikesTable, eq: eq)).map<void>((_) {}),
      ResourceSuccess<List<SBRow>>() =>
        (await _h.db.post(DiscoverHelper.commentLikesTable, eq)).map<void>((_) {}),
      ResourceError<List<SBRow>>(:final failure) =>
        Resource<void>.error(failure),
      ResourceLoading<List<SBRow>>() => const Resource<void>.loading(),
    };
  }

  @override
  Future<Resource<void>> postComment(
    String artworkId,
    String content, {
    String? parentId,
  }) async {
    final text = content.trim();
    if (text.isEmpty || text.length > 1000) {
      return const Resource<void>.error(
        ValidationFailure('Comments must be 1–1000 characters.'),
      );
    }
    final auth = await _h.authUserId();
    if (auth case ResourceError<String>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final result = await _h.db.post(SupabaseTables.comments, {
      'artwork_id': artworkId,
      'user_id': (auth as ResourceSuccess<String>).data,
      'content': text,
      if (parentId != null) 'parent_id': parentId,
    });
    return result.map<void>((_) {});
  }

  @override
  Future<Resource<void>> deleteComment(String commentId) async {
    final result = await _h.db.delete(
      SupabaseTables.comments,
      eq: {'id': commentId},
    );
    if (result case ResourceSuccess<List<SBRow>>(:final data)
        when data.isEmpty) {
      return const Resource<void>.error(
        NotFoundFailure(
          'Comment not found or you cannot delete it.',
          statusCode: 404,
        ),
      );
    }
    return result.map<void>((_) {});
  }

  // ── GET USER LIKED ARTWORKS ──────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getUserLikedArtworks(
    String uid,
  ) {
    return _h.getRelationPage(
      table: DiscoverHelper.likesTable,
      uid: uid,
    );
  }

  // ── GET USER SAVED ARTWORKS ──────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getUserSavedArtworks(
    String uid,
  ) async {
    final auth = await _h.authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) when data == uid => _h.getRelationPage(
          table: DiscoverHelper.bookmarksTable,
          uid: uid,
        ),
      ResourceSuccess<String>() => const Resource<ArtworkListModel>.error(
          AuthFailure(
            'You can only access your own saved artworks.',
            statusCode: 403,
          ),
        ),
      ResourceError<String>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),
      ResourceLoading<String>() => const Resource<ArtworkListModel>.loading(),
    };
  }

  // ── POST ARTWORK ─────────────────────────────────────────

  @override
  Future<Resource<void>> postArtwork(
    PostArtworkModel artwork,
  ) async {
    final auth = await _h.authUserId();
    if (auth case ResourceError<String>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final uid = (auth as ResourceSuccess<String>).data;

    final uploaded = await _h.uploadImages(uid, artwork.images);
    if (uploaded case ResourceError<List<SBRow>>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final images = (uploaded as ResourceSuccess<List<SBRow>>).data;

    final created = await _h.db.post(
      SupabaseTables.artworks,
      {...artwork.toJson(), 'user_id': uid},
    );
    if (created case ResourceError<SBRow>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final artworkId = (created as ResourceSuccess<SBRow>).data['id'] as String;

    final saved = await _h.saveImages(artworkId, images);
    if (saved case ResourceError<void>()) {
      // Don't leave an artwork without its image behind.
      await _h.db.delete(
        SupabaseTables.artworks,
        eq: {'id': artworkId, 'user_id': uid},
      );
    }
    return saved;
  }

  // ── UPDATE ARTWORK ───────────────────────────────────────

  @override
  Future<Resource<void>> updateArtwork(
    String artworkId,
    PostArtworkModel artwork,
  ) async {
    final auth = await _h.authUserId();
    if (auth case ResourceError<String>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final uid = (auth as ResourceSuccess<String>).data;

    final uploaded = await _h.uploadImages(uid, artwork.images);
    if (uploaded case ResourceError<List<SBRow>>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final images = (uploaded as ResourceSuccess<List<SBRow>>).data;

    final result = await _h.db.patch(
      SupabaseTables.artworks,
      artwork.toJson(),
      eq: {'id': artworkId, 'user_id': uid},
    );

    if (result case ResourceSuccess<List<SBRow>>(:final data)
        when data.isEmpty) {
      return const Resource<void>.error(
        NotFoundFailure(
          'Artwork not found or you do not own it.',
          statusCode: 404,
        ),
      );
    }
    if (result case ResourceError<List<SBRow>>(:final failure)) {
      return Resource<void>.error(failure);
    }

    // A new image replaces the old one(s).
    if (images.isEmpty) return const Resource<void>.success(null);
    final cleared = await _h.db.delete(
      SupabaseTables.artworkImages,
      eq: {'artwork_id': artworkId},
    );
    if (cleared case ResourceError<List<SBRow>>(:final failure)) {
      return Resource<void>.error(failure);
    }
    return _h.saveImages(artworkId, images);
  }

  // ── CATEGORIES ───────────────────────────────────────────

  @override
  Future<Resource<List<ArtworkCategoryModel>>> getCategories() async {
    final result = await _h.db.get(
      SupabaseTables.categories,
      columns: 'id,name,slug',
      orderBy: 'name',
    );
    return result.map(
      (rows) => rows.map(ArtworkCategoryModel.fromJson).toList(),
    );
  }

  // ── DELETE ARTWORK ───────────────────────────────────────

  @override
  Future<Resource<void>> deleteArtwork(
    String artworkId,
  ) async {
    final auth = await _h.authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) =>
        _h.deleteOwnArtwork(artworkId, data),
      ResourceError<String>(:final failure) => Resource<void>.error(failure),
      ResourceLoading<String>() => const Resource<void>.loading(),
    };
  }

  // ── TOGGLE LIKE ──────────────────────────────────────────

  // ── TOGGLE LIKE ──────────────────────────────────────────

  @override
  Future<Resource<void>> toggleLike(String artworkId) async {
    if (artworkId.trim().isEmpty) {
      return const Resource<void>.error(
        ValidationFailure('Invalid artwork ID.'),
      );
    }

    final auth = await _h.authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) => _h.toggleLikeForUser(
          artworkId: artworkId,
          uid: data,
        ),
      ResourceError<String>(:final failure) => Resource<void>.error(failure),
      ResourceLoading<String>() => const Resource<void>.loading(),
    };
  }

  // ── TOGGLE SAVE ──────────────────────────────────────────

  @override
  Future<Resource<void>> toggleSave(
    String artworkId,
  ) {
    return _h.toggleRelation(
      table: DiscoverHelper.bookmarksTable,
      artworkId: artworkId,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EXPLORE
  // Needs supabase/explore.sql (the `get_explore` function).
  // ═══════════════════════════════════════════════════════════

  @override
  Future<Resource<ExploreContent>> fetchExplore({String? category}) async {
    final result = await _h.db.rpc<Map<String, dynamic>>(
      SupabaseRpc.getExplore,
      params: {'p_category': category},
    );
    return result.map(_h.toExplore);
  }
}
