import 'dart:io';

import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/network/client/sb_client.dart';
import 'package:artora/src/network/constants/supabase_tables.dart';
import 'package:artora/src/network/failures/failure.dart';
import 'package:artora/src/network/resource/resource.dart';
import 'package:artora/src/network/constants/supabase_buckets.dart';
import 'package:artora/src/services/auth_service.dart';
import 'package:artora/src/services/supabase_storage_service.dart';


/// Queries, row mapping and shared logic behind [DiscoverUsecaseImpl].
///
/// The usecase keeps only the public operations; anything reusable or
/// internal lives here.
class DiscoverHelper {
  const DiscoverHelper();

  static const int pageSize = 20;

  static const String artworkColumns = '*,likes_count:likes(count),'
      'comments_count:comments(count),'
      'category:categories(id,name,slug),'
      'images:artwork_images(image_url,thumbnail_url,mime_type,size,position)';

  static const String likesTable = 'likes';
  static const String bookmarksTable = 'artwork_bookmarks';

  SBClient get db => SBClient.instance;
  AuthService get authService => AuthService.instance;
  SupabaseStorageService get storage => SupabaseStorageService.instance;

  Future<Resource<String>> authUserId() async {
    final current = await authService.getCurrentUser();

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

  Future<String?> viewerId() async {
    final current = await authService.getCurrentUser();

    return current.fold<String?>(
      (_) => null,
      (user) => user?['id'] as String?,
    );
  }

  static const String profileColumns =
      'id,username,display_name,bio,avatar_path,cover_path,'
      'website_url,social_links,specialties';

  Future<Resource<ArtworkModel>> withProfile(SBRow artwork) async {
    final profile = await db.getOne(
      SupabaseTables.profiles,
      columns: profileColumns,
      eq: {'id': artwork['user_id']},
    );
    // A missing profile shouldn't hide the artwork; the artist row just stays off.
    final row = switch (profile) {
      ResourceSuccess<SBRow>(:final data) => {
          ...artwork,
          'profile': {
            ...data,
            'avatar_url': storage.publicUrl(
              SupabaseBuckets.avatars,
              data['avatar_path'] as String?,
            ),
          },
        },
      _ => artwork,
    };
    return (await attachViewerState([row])).map(
      (rows) => ArtworkModel.fromJson(rows.first),
    );
  }

  // Needs supabase/comments.sql (table, FK to profiles, RLS, realtime).

  static const String commentLikesTable = 'comment_likes';

  static const String commentColumns =
      'id,artwork_id,user_id,parent_id,content,created_at,'
      // `!comments_user_id_fkey` picks the author; comment_likes would
      // otherwise give a second (many-to-many) path to profiles.
      'profile:profiles!comments_user_id_fkey(id,username,display_name,avatar_path)';

  /// Adds `replies_count` from one `parent_id` query. An embedded count on
  /// the self-referencing `comments` table is ambiguous in PostgREST and can
  /// silently return nothing, which left the totals wrong.
  Future<Resource<List<SBRow>>> withReplyCounts(
    Resource<List<SBRow>> result,
  ) async {
    final rows = result.dataOrNull;
    if (rows == null) return result;
    final ids = rows.map((r) => r['id']).whereType<String>().toList();
    final counts = <String, int>{};
    if (ids.isNotEmpty) {
      final replies = await db.get(
        SupabaseTables.comments,
        columns: 'parent_id',
        filter: (query) => query.inFilter('parent_id', ids),
      );
      for (final reply in replies.dataOrNull ?? const <SBRow>[]) {
        final parent = reply['parent_id'];
        if (parent is String) counts[parent] = (counts[parent] ?? 0) + 1;
      }
    }
    return Resource.success([
      for (final row in rows)
        {
          ...row,
          'replies_count': [
            {'count': counts[row['id']] ?? 0},
          ],
        },
    ]);
  }

  /// Adds like counts and the viewer's `is_liked` flags, then parses.
  ///
  /// Counted from one `comment_likes` query rather than a PostgREST embed,
  /// so it doesn't depend on the schema cache knowing the relationship.
  // shortcut: pulls every like row for the page (≤20 comments); move to an
  // RPC or a stored count when comments get thousands of likes.
  Future<Resource<List<CommentModel>>> toComments(
    Resource<List<SBRow>> result,
  ) async {
    final rows = result.dataOrNull;
    if (rows == null) {
      return result.map((_) => const <CommentModel>[]);
    }
    final uid = await viewerId();
    final ids = rows.map((r) => r['id']).whereType<String>().toList();
    final counts = <String, int>{};
    final liked = <String>{};
    if (ids.isNotEmpty) {
      final likes = await db.get(
        commentLikesTable,
        columns: 'comment_id,user_id',
        filter: (query) => query.inFilter('comment_id', ids),
      );
      // Missing like data isn't worth failing the whole list; counts show 0.
      for (final like in likes.dataOrNull ?? const <SBRow>[]) {
        final id = like['comment_id'];
        if (id is! String) continue;
        counts[id] = (counts[id] ?? 0) + 1;
        if (uid != null && like['user_id'] == uid) liked.add(id);
      }
    }
    return Resource.success([
      for (final row in rows)
        CommentModel.fromJson({
          ...withAvatarUrl(row),
          'likes_count': [
            {'count': counts[row['id']] ?? 0},
          ],
          'is_liked': liked.contains(row['id']),
        }),
    ]);
  }

  /// Resolves the embedded profile's `avatar_path` to a public `avatar_url`.
  SBRow withAvatarUrl(SBRow row) {
    final profile = row['profile'];
    if (profile is! Map<String, dynamic>) return row;
    return {
      ...row,
      'profile': {
        ...profile,
        'avatar_url': storage.publicUrl(
          SupabaseBuckets.avatars,
          profile['avatar_path'] as String?,
        ),
      },
    };
  }

  /// Writes the `artwork_images` rows (first image at position 0).
  Future<Resource<void>> saveImages(
    String artworkId,
    List<SBRow> images,
  ) async {
    if (images.isEmpty) return const Resource<void>.success(null);
    final rows = [
      for (var i = 0; i < images.length; i++)
        {...images[i], 'artwork_id': artworkId, 'position': i},
    ];
    return (await db.postMany(SupabaseTables.artworkImages, rows))
        .map<void>((_) {});
  }

  static const Map<String, String> mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// Uploads [files] to the public artworks bucket and returns the matching
  /// `artwork_images` row values (without `artwork_id` / `position`).
  Future<Resource<List<SBRow>>> uploadImages(
    String uid,
    List<File> files,
  ) async {
    final images = <SBRow>[];
    for (final file in files) {
      final dot = file.path.lastIndexOf('.');
      final ext =
          dot == -1 ? 'jpg' : file.path.substring(dot + 1).toLowerCase();
      final mime = mimeByExtension[ext];
      if (mime == null) {
        return const Resource<List<SBRow>>.error(
          ValidationFailure('Only PNG, JPG and WebP images are supported.'),
        );
      }
      final int size;
      try {
        size = await file.length();
      } on FileSystemException {
        return const Resource<List<SBRow>>.error(
          ValidationFailure(
              'The selected image is no longer available. Please pick it again.'),
        );
      }
      if (size > StorageLimits.maxArtworkBytes) {
        return const Resource<List<SBRow>>.error(
          ValidationFailure('Images must be 20 MB or smaller.'),
        );
      }

      final path = SupabaseBuckets.artworkPath(
        uid,
        DateTime.now().microsecondsSinceEpoch.toString(),
        ext: ext,
      );
      final upload = await storage.uploadFile(
        bucket: SupabaseBuckets.artworks,
        path: path,
        file: file,
        contentType: mime,
      );
      final failure = upload.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) return Resource<List<SBRow>>.error(failure);
      final url = storage.publicUrl(SupabaseBuckets.artworks, path);

      images.add({
        'image_url': url,
        // thumbnail_url is NOT NULL; reuse the full image until thumbnails exist.
        'thumbnail_url': url,
        'mime_type': mime,
        'size': size,
      });
    }
    return Resource<List<SBRow>>.success(images);
  }

  Future<Resource<void>> deleteOwnArtwork(
    String artworkId,
    String uid,
  ) async {
    final result = await db.delete(
      SupabaseTables.artworks,
      eq: {
        'id': artworkId,
        'user_id': uid,
      },
    );

    if (result
        case ResourceSuccess<List<SBRow>>(
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

  Future<Resource<void>> toggleLikeForUser({
    required String artworkId,
    required String uid,
  }) async {
    final eq = <String, Object?>{
      'user_id': uid,
      'artwork_id': artworkId,
    };

    final existing = await db.get(
      likesTable,
      columns: 'artwork_id',
      eq: eq,
      limit: 1,
    );

    return switch (existing) {
      ResourceSuccess<List<SBRow>>(:final data) when data.isNotEmpty =>
        (await db.delete(
          likesTable,
          eq: eq,
        )).map<void>((_) {}),

      ResourceSuccess<List<SBRow>>() =>
        (await db.post(
          likesTable,
          eq,
        )).map<void>((_) {}),

      ResourceError<List<SBRow>>(:final failure) =>
        Resource<void>.error(failure),

      ResourceLoading<List<SBRow>>() =>
        const Resource<void>.loading(),
    };
  }

  Future<Resource<List<SBRow>>> attachViewerState(
    List<SBRow> rows,
  ) async {
    if (rows.isEmpty) {
      return const Resource<List<SBRow>>.success([]);
    }

    final uid = await viewerId();

    if (uid == null) {
      return Resource<List<SBRow>>.success([
        for (final row in rows)
          {
            ...row,
            'is_liked': false,
            'is_bookmarked': false,
          },
      ]);
    }

    final ids = rows
        .map((row) => row['id'])
        .whereType<String>()
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return Resource<List<SBRow>>.success([
        for (final row in rows)
          {
            ...row,
            'is_liked': false,
            'is_bookmarked': false,
          },
      ]);
    }

    final liked = await getRelationIds(
      table: likesTable,
      uid: uid,
      artworkIds: ids,
    );

    return switch (liked) {
      ResourceSuccess<Set<String>>(:final data) => attachBookmarks(
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

  Future<Resource<void>> toggleRelation({
    required String table,
    required String artworkId,
  }) async {
    final auth = await authUserId();

    return switch (auth) {
      ResourceSuccess<String>(:final data) => toggleForUser(
          table: table,
          artworkId: artworkId,
          uid: data,
        ),
      ResourceError<String>(:final failure) => Resource<void>.error(failure),
      ResourceLoading<String>() => const Resource<void>.loading(),
    };
  }

  Future<Resource<void>> toggleForUser({
    required String table,
    required String artworkId,
    required String uid,
  }) async {
    final eq = <String, Object?>{
      'user_id': uid,
      'artwork_id': artworkId,
    };

    final existing = await db.getOne(
      table,
      columns: 'artwork_id',
      eq: eq,
    );

    return switch (existing) {
      // Relation already exists: remove it.
      ResourceSuccess<SBRow>() => (await db.delete(
          table,
          eq: eq,
        ))
            .map<void>((_) {}),

      // Relation does not exist: create it.
      ResourceError<SBRow>(:final failure) when failure is NotFoundFailure =>
        (await db.post(
          table,
          {
            'user_id': uid,
            'artwork_id': artworkId,
          },
        ))
            .map<void>((_) {}),
      ResourceError<SBRow>(:final failure) => Resource<void>.error(failure),
      ResourceLoading<SBRow>() => const Resource<void>.loading(),
    };
  }

  Future<Resource<ArtworkListModel>> getArtworkPage({
    Map<String, Object?>? eq,
  }) async {
    final result = await db.get(
      SupabaseTables.artworks,
      columns: artworkColumns,
      eq: eq,
      orderBy: 'created_at',
      ascending: false,
      limit: pageSize + 1,
    );

    return switch (result) {
      ResourceSuccess<List<SBRow>>(:final data) => fromArtworkRows(data),
      ResourceError<List<SBRow>>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),
      ResourceLoading<List<SBRow>>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  Future<Resource<ArtworkListModel>> fromArtworkRows(
    List<SBRow> rows,
  ) {
    final hasMore = rows.length > pageSize;
    final page = rows.take(pageSize).toList();

    final nextCursor =
        hasMore && page.isNotEmpty ? page.last['created_at'] as String? : null;

    return buildArtworkList(
      page,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  Future<Resource<ArtworkListModel>> getRelationPage({
    required String table,
    required String uid,
  }) async {
    final result = await db.get(
      table,
      columns: 'artwork_id,created_at',
      eq: {'user_id': uid},
      orderBy: 'created_at',
      ascending: false,
      limit: pageSize + 1,
    );

    return switch (result) {
      ResourceSuccess<List<SBRow>>(:final data) => fromRelationRows(data),
      ResourceError<List<SBRow>>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),
      ResourceLoading<List<SBRow>>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  Future<Resource<ArtworkListModel>> fromRelationRows(
    List<SBRow> relations,
  ) async {
    final hasMore = relations.length > pageSize;
    final page = relations.take(pageSize).toList();

    final ids =
        page.map((row) => row['artwork_id']).whereType<String>().toList();

    final nextCursor =
        hasMore && page.isNotEmpty ? page.last['created_at'] as String? : null;

    if (ids.isEmpty) {
      return buildArtworkList(
        [],
        hasMore: false,
      );
    }

    final result = await db.get(
      SupabaseTables.artworks,
      columns: artworkColumns,
      filter: (query) => query.inFilter('id', ids),
    );

    return switch (result) {
      ResourceSuccess<List<SBRow>>(:final data) => buildArtworkList(
          sortByIds(data, ids),
          hasMore: hasMore,
          nextCursor: nextCursor,
        ),
      ResourceError<List<SBRow>>(:final failure) =>
        Resource<ArtworkListModel>.error(failure),
      ResourceLoading<List<SBRow>>() =>
        const Resource<ArtworkListModel>.loading(),
    };
  }

  static List<SBRow> sortByIds(
    List<SBRow> rows,
    List<String> ids,
  ) {
    final byId = <String, SBRow>{
      for (final row in rows)
        if (row['id'] is String) row['id'] as String: row,
    };

    return ids
        .where((id) => byId.containsKey(id))
        .map((id) => byId[id]!)
        .toList();
  }

  Future<Resource<ArtworkListModel>> buildArtworkList(
    List<SBRow> rows, {
    required bool hasMore,
    String? nextCursor,
  }) async {
    final result = await attachViewerState(rows);

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

  Future<Resource<List<SBRow>>> attachBookmarks({
    required List<SBRow> rows,
    required String uid,
    required List<String> artworkIds,
    required Set<String> likedIds,
  }) async {
    final saved = await getRelationIds(
      table: bookmarksTable,
      uid: uid,
      artworkIds: artworkIds,
    );

    final savedIds = saved.dataOrNull ?? const <String>{};
    return Resource.success([
      for (final row in rows)
        {
          ...row,
          'is_liked': likedIds.contains(row['id']),
          'is_bookmarked': savedIds.contains(row['id']),
        },
    ]);
  }

  Future<Resource<Set<String>>> getRelationIds({
    required String table,
    required String uid,
    required List<String> artworkIds,
  }) async {
    final result = await db.get(
      table,
      columns: 'artwork_id',
      eq: {'user_id': uid},
      filter: (query) => query.inFilter(
        'artwork_id',
        artworkIds,
      ),
    );

    return result.map(
      (rows) =>
          rows.map((row) => row['artwork_id']).whereType<String>().toSet(),
    );
  }

  // ── SEARCH ───────────────────────────────────────────────

  static const String profileSearchColumns =
      'id,username,display_name,avatar_path,specialties';

  /// Artworks (title, tag, category or artist match), artists (username or
  /// name) and tags, all from public data.
  // shortcut: the tag list comes from the matched artworks only; add a
  // `tags` table or an RPC when search needs to cover every tag.
  Future<Resource<SearchResults>> search(String raw) async {
    // Characters that would break PostgREST's or()/ilike syntax.
    final q = raw
        .trim()
        .toLowerCase()
        .replaceFirst('#', '')
        .replaceAll(RegExp(r'[,()*%\\{}"]'), '');
    if (q.isEmpty) return const Resource<SearchResults>.success(SearchResults.empty);

    final people = await db.get(
      SupabaseTables.profiles,
      columns: profileSearchColumns,
      filter: (query) =>
          query.or('username.ilike.*$q*,display_name.ilike.*$q*'),
      limit: 10,
    );
    final personRows = people.dataOrNull ?? const <SBRow>[];
    final personIds = personRows.map((r) => r['id']).whereType<String>().toList();

    final categories = await db.get(
      SupabaseTables.categories,
      columns: 'id',
      filter: (query) => query.ilike('name', '%$q%'),
    );
    final categoryIds = (categories.dataOrNull ?? const <SBRow>[])
        .map((r) => r['id'])
        .whereType<String>()
        .toList();

    final artworks = await db.get(
      SupabaseTables.artworks,
      columns: artworkColumns,
      eq: {'visibility': 'public'},
      filter: (query) => query.or([
        'title.ilike.*$q*',
        'tags.cs.{$q}',
        if (personIds.isNotEmpty) 'user_id.in.(${personIds.join(',')})',
        if (categoryIds.isNotEmpty)
          'category_id.in.(${categoryIds.join(',')})',
      ].join(',')),
      orderBy: 'created_at',
      ascending: false,
      limit: pageSize,
    );
    final artworkRows = artworks.dataOrNull;
    if (artworkRows == null) {
      return artworks.map((_) => SearchResults.empty);
    }

    // One lookup for every author on screen: profile fields + follower counts.
    final authorIds = {
      ...personIds,
      ...artworkRows.map((r) => r['user_id']).whereType<String>(),
    }.toList();
    final profileRows = authorIds.isEmpty
        ? const <SBRow>[]
        : (await db.get(
              SupabaseTables.profiles,
              columns: profileSearchColumns,
              filter: (query) => query.inFilter('id', authorIds),
            ))
                .dataOrNull ??
            const <SBRow>[];
    final followers = <String, int>{};
    if (authorIds.isNotEmpty) {
      final follows = await db.get(
        SupabaseTables.follows,
        columns: 'following_id',
        filter: (query) => query.inFilter('following_id', authorIds),
      );
      for (final row in follows.dataOrNull ?? const <SBRow>[]) {
        final id = row['following_id'];
        if (id is String) followers[id] = (followers[id] ?? 0) + 1;
      }
    }

    Artist toArtist(SBRow row) => Artist(
          id: row['id'] as String? ?? '',
          username: row['username'] as String? ?? '',
          displayName: row['display_name'] as String? ?? '',
          avatarUrl: storage.publicUrl(
                SupabaseBuckets.avatars,
                row['avatar_path'] as String?,
              ) ??
              '',
          followers: followers[row['id']] ?? 0,
          specialties: [
            for (final s in row['specialties'] as List<dynamic>? ?? const [])
              s.toString(),
          ],
        );
    final authors = {
      for (final row in profileRows) row['id'] as String? ?? '': toArtist(row),
    };

    final models = [
      for (final row in artworkRows) ArtworkModel.fromJson(row),
    ];
    return Resource<SearchResults>.success(
      SearchResults(
        artworks: [
          for (final m in models)
            Artwork(
              id: m.id,
              title: m.title,
              imageUrl: m.images.isEmpty
                  ? ''
                  : m.images.first.thumbnailUrl ?? m.images.first.url,
              aspectRatio: 1,
              artist: authors[m.userId] ??
                  Artist(
                    id: m.userId,
                    username: '',
                    displayName: '',
                    avatarUrl: '',
                  ),
              category: m.category?.name ?? '',
              tags: m.tags,
              likes: m.likesCount,
              comments: m.commentsCount,
            ),
        ],
        artists: [
          for (final id in personIds)
            if (authors[id] case final artist?) artist,
        ],
        tags: ({
          for (final m in models)
            for (final tag in m.tags)
              if (tag.toLowerCase().contains(q)) tag.toLowerCase(),
        }.toList()
          ..sort()),
      ),
    );
  }

  ExploreContent toExplore(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) => [
          for (final e in json[key] as List<dynamic>? ?? const [])
            if (e is Map<String, dynamic>) e,
        ];

    List<String> strings(Object? value) => [
          for (final e in value as List<dynamic>? ?? const []) e.toString(),
        ];

    Artist artist(Map<String, dynamic> j) => Artist(
          id: j['id'] as String? ?? '',
          username: j['username'] as String? ?? '',
          displayName: j['display_name'] as String? ?? '',
          avatarUrl: storage.publicUrl(
                SupabaseBuckets.avatars,
                j['avatar_path'] as String?,
              ) ??
              '',
          followers: (j['followers'] as num?)?.toInt() ?? 0,
          specialties: strings(j['specialties']),
        );

    return (
      categories: [
        for (final c in rows('categories'))
          ArtCategory(
            name: c['name'] as String? ?? '',
            imageUrl: c['image_url'] as String? ?? '',
          ),
      ],
      trendingTags: strings(json['trending_tags']),
      collections: [
        for (final c in rows('collections'))
          ArtCollection(
            id: c['id'] as String? ?? '',
            title: c['title'] as String? ?? '',
            coverUrl: c['cover_url'] as String? ?? '',
            artworkCount: (c['artwork_count'] as num?)?.toInt() ?? 0,
          ),
      ],
      artists: rows('artists').map(artist).toList(),
      editorsPicks: [
        for (final p in rows('editors_picks'))
          Artwork(
            id: p['id'] as String? ?? '',
            title: p['title'] as String? ?? '',
            imageUrl: p['image_url'] as String? ?? '',
            aspectRatio: 1, // picks render in fixed-size tiles
            artist: artist(p['artist'] as Map<String, dynamic>? ?? const {}),
            category: p['category'] as String? ?? '',
            tags: strings(p['tags']),
            likes: (p['likes'] as num?)?.toInt() ?? 0,
            comments: (p['comments'] as num?)?.toInt() ?? 0,
            isEditorsPick: true,
          ),
      ],
    );
  }
}
