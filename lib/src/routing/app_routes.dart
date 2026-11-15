/// Centralized route path constants for GoRouter.
///
/// Use these variables instead of raw strings throughout the app.
/// Example: `context.go(AppRoutes.onboarding)` instead of `context.go('/')`.
abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profileSetup = '/profile-setup';
  static const String explore = '/explore';
  static const String saved = '/saved';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Create an artwork.
  static const String createArtwork = '/artwork/new';

  /// Edit an artwork; use [editArtworkPath] to build the location.
  static const String editArtwork = '/artwork/:id/edit';
  static String editArtworkPath(String id) => '/artwork/$id/edit';

  /// Post view; declared after `new` / `preview` so those still match first.
  static const String artworkDetail = '/artwork/:id';
  static String artworkDetailPath(String id) => '/artwork/$id';

  /// Full comments page for an artwork.
  static const String artworkComments = '/artwork/:id/comments';
  static String artworkCommentsPath(String id) => '/artwork/$id/comments';

  /// Another artist's profile; use [artistProfilePath] to build the location.
  static const String artistProfile = '/artist/:id';
  static String artistProfilePath(String id) => '/artist/$id';

  /// Followers & Following of an artist; `tab` is `followers` or `following`.
  static const String artistConnections = '/artist/:id/connections';
  static String artistConnectionsPath(String id, {bool following = false}) =>
      '/artist/$id/connections?tab=${following ? 'following' : 'followers'}';

  /// Image preview; pass the picked `File` as `extra`, pops with the result.
  static const String artworkPreview = '/artwork/preview';

  /// Optional query parameters: `q` (query) and `scope` (`SearchScope.name`).
  static const String search = '/search';

  /// Debug-only component gallery.
  static const String uiShowcase = '/debug/ui-showcase';
}
