
import 'package:artora/src/features/discover/data/discover_usecase.dart';
import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/network/client/sb_client.dart';
import 'package:artora/src/network/constants/supabase_tables.dart';
import 'package:artora/src/network/failures/failure.dart';
import 'package:artora/src/network/resource/resource.dart';
import 'package:artora/src/services/auth_service.dart';

class DiscoverUsecaseImpl implements DiscoverUsecase {
  static const int _pageSize = 20;

  static const String _artworkColumns =
      '*,category:categories(id,name,slug)';

  static const String _likesTable = 'artwork_likes';
  static const String _bookmarksTable = 'artwork_bookmarks';

  SBClient get _db => SBClient.instance;
  AuthService get _auth => AuthService.instance;

  // ── AUTH HELPERS ─────────────────────────────────────────

  Future<Resource<String>> _authUserId() async {
    final current = await _auth.getCurrentUser();

    return current.fold<Resource<String>>(
      (failure) => Resource<String>.error(failure),
      (user) {
        final id = user?['id'];

        if (id is! String || id.isEmpty) {
          return const Resource<String>.error(
            AuthFailure(
              'You are not signed in.',
              statusCode: 401,
            ),
          );
        }

        return Resource<String>.success(id);
      },
    );
  }

  Future<String?> _viewerId() async {
    final current = await _auth.getCurrentUser();

    return current.fold<String?>(
      (_) => null,
      (user) => user?['id'] as String?,
    );
  }

  // ── GET PUBLIC FEED ──────────────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getPublicFeed() {
    return _getArtworkPage(
      eq: {'visibility': 'public'},
    );
  }

  // ── GET USER FEED ────────────────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getUserFeed(
    String uid,
  ) async {
    final viewerId = await _viewerId();

    return _getArtworkPage(
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
    final result = await _db.getOne(
      SupabaseTables.artworks,
      columns: _artworkColumns,
      eq: {'id': postId},
    );

    return switch (result) {
      ResourceSuccess<SBRow>(:final data) =>
        (await _attachViewerState([data])).map(
          (rows) => ArtworkModel.fromJson(rows.first),
        ),

      ResourceError<SBRow>(:final failure) =>
        Resource<ArtworkModel>.error(failure),

      ResourceLoading<SBRow>() =>
        const Resource<ArtworkModel>.loading(),
    };
  }

  // ── GET USER LIKED ARTWORKS ──────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getUserLikedArtworks(
    String uid,
  ) {
    return _getRelationPage(
      table: _likesTable,
      uid: uid,
    );
  }

  // ── GET USER SAVED ARTWORKS ──────────────────────────────

  @override
  Future<Resource<ArtworkListModel>> getUserSavedArtworks(
    String uid,
  ) async {
    final auth = await _authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) when data == uid =>
        _getRelationPage(
          table: _bookmarksTable,
          uid: uid,
        ),

      ResourceSuccess<String>() =>
        const Resource<ArtworkListModel>.error(
          AuthFailure(
            'You can only access your own saved artworks.',
            statusCode: 403,
          ),
        ),

      ResourceError<String>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),

      ResourceLoading<String>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  // ── POST ARTWORK ─────────────────────────────────────────

  @override
  Future<Resource<void>> postArtwork(
    PostArtworkModel artwork,
  ) async {
    final auth = await _authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) =>
        (await _db.post(
          SupabaseTables.artworks,
          {
            ...artwork.toJson(),
            'user_id': data,
          },
        )).map<void>((_) {}),

      ResourceError<String>(:final failure) =>
        Resource<void>.error(failure),

      ResourceLoading<String>() =>
        const Resource<void>.loading(),
    };
  }

  // ── DELETE ARTWORK ───────────────────────────────────────

  @override
  Future<Resource<void>> deleteArtwork(
    String artworkId,
  ) async {
    final auth = await _authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) =>
        _deleteOwnArtwork(artworkId, data),

      ResourceError<String>(:final failure) =>
        Resource<void>.error(failure),

      ResourceLoading<String>() =>
        const Resource<void>.loading(),
    };
  }

  Future<Resource<void>> _deleteOwnArtwork(
    String artworkId,
    String uid,
  ) async {
    final result = await _db.delete(
      SupabaseTables.artworks,
      eq: {
        'id': artworkId,
        'user_id': uid,
      },
    );

    if (result case ResourceSuccess<List<SBRow>>(
      :final data,
    ) when data.isEmpty) {
      return const Resource<void>.error(
        NotFoundFailure(
          'Artwork not found or you do not own it.',
          statusCode: 404,
        ),
      );
    }

    return result.map<void>((_) {});
  }

  // ── TOGGLE LIKE ──────────────────────────────────────────

  @override
  Future<Resource<void>> toggleLike(
    String artworkId,
  ) {
    return _toggleRelation(
      table: _likesTable,
      artworkId: artworkId,
    );
  }

  // ── TOGGLE SAVE ──────────────────────────────────────────

  @override
  Future<Resource<void>> toggleSave(
    String artworkId,
  ) {
    return _toggleRelation(
      table: _bookmarksTable,
      artworkId: artworkId,
    );
  }

  // ── SHARED TOGGLE LOGIC ──────────────────────────────────

  Future<Resource<void>> _toggleRelation({
    required String table,
    required String artworkId,
  }) async {
    final auth = await _authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) =>
        _toggleForUser(
          table: table,
          artworkId: artworkId,
          uid: data,
        ),

      ResourceError<String>(:final failure) =>
        Resource<void>.error(failure),

      ResourceLoading<String>() =>
        const Resource<void>.loading(),
    };
  }

  Future<Resource<void>> _toggleForUser({
    required String table,
    required String artworkId,
    required String uid,
  }) async {
    final eq = <String, Object?>{
      'user_id': uid,
      'artwork_id': artworkId,
    };

    final existing = await _db.getOne(
      table,
      columns: 'artwork_id',
      eq: eq,
    );

    return switch (existing) {
      // Relation already exists: remove it.
      ResourceSuccess<SBRow>() =>
        (await _db.delete(
          table,
          eq: eq,
        )).map<void>((_) {}),

      // Relation does not exist: create it.
      ResourceError<SBRow>(:final failure)
          when failure is NotFoundFailure =>
        (await _db.post(
          table,
          {
            'user_id': uid,
            'artwork_id': artworkId,
          },
        )).map<void>((_) {}),

      ResourceError<SBRow>(:final failure) =>
        Resource<void>.error(failure),

      ResourceLoading<SBRow>() =>
        const Resource<void>.loading(),
    };
  }

  // ── SHARED ARTWORK FEED ──────────────────────────────────

  Future<Resource<ArtworkListModel>> _getArtworkPage({
    Map<String, Object?>? eq,
  }) async {
    final result = await _db.get(
      SupabaseTables.artworks,
      columns: _artworkColumns,
      eq: eq,
      orderBy: 'created_at',
      ascending: false,
      limit: _pageSize + 1,
    );

    return switch (result) {
      ResourceSuccess<List<SBRow>>(:final data) =>
        _fromArtworkRows(data),

      ResourceError<List<SBRow>>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),

      ResourceLoading<List<SBRow>>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  Future<Resource<ArtworkListModel>> _fromArtworkRows(
    List<SBRow> rows,
  ) {
    final hasMore = rows.length > _pageSize;
    final page = rows.take(_pageSize).toList();

    final nextCursor = hasMore && page.isNotEmpty
        ? page.last['created_at'] as String?
        : null;

    return _buildArtworkList(
      page,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  // ── SHARED LIKED / SAVED FEED ────────────────────────────

  Future<Resource<ArtworkListModel>> _getRelationPage({
    required String table,
    required String uid,
  }) async {
    final result = await _db.get(
      table,
      columns: 'artwork_id,created_at',
      eq: {'user_id': uid},
      orderBy: 'created_at',
      ascending: false,
      limit: _pageSize + 1,
    );

    return switch (result) {
      ResourceSuccess<List<SBRow>>(:final data) =>
        _fromRelationRows(data),

      ResourceError<List<SBRow>>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),

      ResourceLoading<List<SBRow>>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  Future<Resource<ArtworkListModel>> _fromRelationRows(
    List<SBRow> relations,
  ) async {
    final hasMore = relations.length > _pageSize;
    final page = relations.take(_pageSize).toList();

    final ids = page
        .map((row) => row['artwork_id'])
        .whereType<String>()
        .toList();

    final nextCursor = hasMore && page.isNotEmpty
        ? page.last['created_at'] as String?
        : null;

    if (ids.isEmpty) {
      return _buildArtworkList(
        [],
        hasMore: false,
      );
    }

    final result = await _db.get(
      SupabaseTables.artworks,
      columns: _artworkColumns,
      filter: (query) => query.inFilter('id', ids),
    );

    return switch (result) {
      ResourceSuccess<List<SBRow>>(:final data) =>
        _buildArtworkList(
          _sortByIds(data, ids),
          hasMore: hasMore,
          nextCursor: nextCursor,
        ),

      ResourceError<List<SBRow>>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),

      ResourceLoading<List<SBRow>>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  static List<SBRow> _sortByIds(
    List<SBRow> rows,
    List<String> ids,
  ) {
    final byId = <String, SBRow>{
      for (final row in rows)
        if (row['id'] is String)
          row['id'] as String: row,
    };

    return ids
        .where((id) => byId.containsKey(id))
        .map((id) => byId[id]!)
        .toList();
  }

  // ── BUILD ARTWORK LIST MODEL ─────────────────────────────

  Future<Resource<ArtworkListModel>> _buildArtworkList(
    List<SBRow> rows, {
    required bool hasMore,
    String? nextCursor,
  }) async {
    final result = await _attachViewerState(rows);

    return result.map(
      (artworks) => ArtworkListModel.fromJson({
        'data': artworks,
        'pagination': {
          'next_cursor': hasMore ? nextCursor : null,
          'has_more': hasMore,
        },
      }),
    );
  }

  // ── ATTACH LIKE AND BOOKMARK FLAGS ───────────────────────

  Future<Resource<List<SBRow>>> _attachViewerState(
    List<SBRow> rows,
  ) async {
    if (rows.isEmpty) {
      return const Resource<List<SBRow>>.success([]);
    }

    final uid = await _viewerId();

    if (uid == null) {
      return Resource<List<SBRow>>.success(
        [
          for (final row in rows)
            {
              ...row,
              'is_liked': false,
              'is_bookmarked': false,
            },
        ],
      );
    }

    final ids = rows
        .map((row) => row['id'])
        .whereType<String>()
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return Resource<List<SBRow>>.success(
        [
          for (final row in rows)
            {
              ...row,
              'is_liked': false,
              'is_bookmarked': false,
            },
        ],
      );
    }

    final liked = await _getRelationIds(
      table: _likesTable,
      uid: uid,
      artworkIds: ids,
    );

    return switch (liked) {
      ResourceSuccess<Set<String>>(:final data) =>
        _attachBookmarks(
          rows: rows,
          uid: uid,
          artworkIds: ids,
          likedIds: data,
        ),

      ResourceError<Set<String>>(:final failure) =>
        Resource<List<SBRow>>.error(failure),

      ResourceLoading<Set<String>>() =>
        const Resource<List<SBRow>>.loading(),
    };
  }

  Future<Resource<List<SBRow>>> _attachBookmarks({
    required List<SBRow> rows,
    required String uid,
    required List<String> artworkIds,
    required Set<String> likedIds,
  }) async {
    final saved = await _getRelationIds(
      table: _bookmarksTable,
      uid: uid,
      artworkIds: artworkIds,
    );

    return saved.map(
      (savedIds) => [
        for (final row in rows)
          {
            ...row,
            'is_liked': likedIds.contains(row['id']),
            'is_bookmarked': savedIds.contains(row['id']),
          },
      ],
    );
  }

  // ── FETCH RELATION IDS ───────────────────────────────────

  Future<Resource<Set<String>>> _getRelationIds({
    required String table,
    required String uid,
    required List<String> artworkIds,
  }) async {
    final result = await _db.get(
      table,
      columns: 'artwork_id',
      eq: {'user_id': uid},
      filter: (query) => query.inFilter(
        'artwork_id',
        artworkIds,
      ),
    );

    return result.map(
      (rows) => rows
          .map((row) => row['artwork_id'])
          .whereType<String>()
          .toSet(),
    );
  }
}
