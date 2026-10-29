import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/imports/core_imports.dart';

/// Data contract for the home feed, explore, search and saved screens.
abstract class DiscoverRepository {
  Future<Resource<Artist>> currentArtist();
  Future<Resource<List<Artwork>>> feed();
  Future<Resource<ExploreContent>> explore();
  Future<Resource<List<String>>> trendingTags();
  Future<Resource<SearchResults>> search(String query);

  /// Ids of the artists the signed-in user follows.
  Future<Resource<Set<String>>> followingIds();
  Future<Resource<void>> setFollowing(String artistId, {required bool following});
  Future<Resource<void>> setLiked(String artworkId, {required bool liked});
  Future<Resource<void>> setBookmarked(
    String artworkId, {
    required bool bookmarked,
  });
}
