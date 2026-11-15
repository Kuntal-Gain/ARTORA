/// Supabase table, view and RPC names. Use these instead of string literals:
/// `client.from(SupabaseTables.artworks)`.
///
/// Keep in sync with the database schema (supabase/migrations).
abstract final class SupabaseTables {
  SupabaseTables._();

  static const String profiles = 'profiles';
  static const String artworks = 'artworks';
  static const String categories = 'categories';
  static const String artworkImages = 'artwork_images';
  static const String tags = 'tags';
  static const String artworkTags = 'artwork_tags';
  static const String likes = 'likes';
  static const String bookmarks = 'bookmarks';
  static const String comments = 'comments';
  static const String follows = 'follows';
  static const String collections = 'collections';
  static const String collectionArtworks = 'collection_artworks';
  static const String notifications = 'notifications';
  static const String reports = 'reports';
  static const String blockedUsers = 'blocked_users';
}

/// Column names shared by several tables.
abstract final class SupabaseColumns {
  SupabaseColumns._();

  static const String id = 'id';
  static const String userId = 'user_id';
  static const String artworkId = 'artwork_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Postgres functions called with `client.rpc(...)`.
abstract final class SupabaseRpc {
  SupabaseRpc._();

  static const String toggleLike = 'toggle_like';
  static const String toggleBookmark = 'toggle_bookmark';
  static const String toggleFollow = 'toggle_follow';
  static const String getExplore = 'get_explore';
  static const String getUserById = 'get_user_by_id';
  static const String listFollowers = 'list_followers';
  static const String listFollowing = 'list_following';
  static const String searchCollections = 'search_collections';
  static const String listUserCollections = 'list_user_collections';
  static const String trendingCollections = 'trending_collections';
  static const String isUsernameAvailable = 'is_username_available';
}
