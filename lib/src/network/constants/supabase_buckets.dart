/// Supabase Storage bucket names and path builders.
///
/// Files are stored under `<userId>/…` so RLS policies can match on the first
/// path segment (`(storage.foldername(name))[1] = auth.uid()::text`).
abstract final class SupabaseBuckets {
  SupabaseBuckets._();

  static const String avatars = 'avatars';
  static const String artworks = 'artworks';
  static const String thumbnails = 'thumbnails';
  static const String banners = 'banners';

  /// Avatar path: `<userId>/avatar.<ext>`.
  static String avatarPath(String userId, {String ext = 'jpg'}) =>
      '$userId/avatar.$ext';

  /// Artwork path: `<userId>/<artworkId>.<ext>`.
  static String artworkPath(String userId, String artworkId,
          {String ext = 'jpg'}) =>
      '$userId/$artworkId.$ext';

  /// Thumbnail path mirrors the artwork path.
  static String thumbnailPath(String userId, String artworkId,
          {String ext = 'jpg'}) =>
      '$userId/$artworkId.$ext';
}

/// Upload limits enforced client-side before hitting Storage.
abstract final class StorageLimits {
  StorageLimits._();

  static const int maxAvatarBytes = 2 * 1024 * 1024;
  static const int maxArtworkBytes = 10 * 1024 * 1024;
  static const List<String> imageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
}
