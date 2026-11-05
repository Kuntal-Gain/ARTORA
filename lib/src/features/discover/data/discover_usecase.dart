import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/imports/imports.dart';

abstract class DiscoverUsecase {
  /// get [public] feed
  Future<Resource<ArtworkListModel>> getPublicFeed();

  /// get [user] feed
  Future<Resource<ArtworkListModel>> getUserFeed(String uid);

  /// get [user] liked artworks
  Future<Resource<ArtworkListModel>> getUserLikedArtworks(String uid);

  /// get [user] saved artworks
  Future<Resource<ArtworkListModel>> getUserSavedArtworks(String uid);

  /// post an new [ARTWORK] to the platform
  Future<Resource<void>> postArtwork(PostArtworkModel artwork);

  /// update an own [ARTWORK]; empty `images` keeps the current ones
  Future<Resource<void>> updateArtwork(
    String artworkId,
    PostArtworkModel artwork,
  );

  /// all artwork categories, by name
  Future<Resource<List<ArtworkCategoryModel>>> getCategories();

  /// get a single [ARTWORK] data here
  Future<Resource<ArtworkModel>> getSinglePost(String postId);

  /// delete a [Artwork] from the platform
  Future<Resource<void>> deleteArtwork(String artworkId);

  /// like/unlike a [Artwork]
  Future<Resource<void>> toggleLike(String artworkId);

  /// save/unsave a [Artwork]
  Future<Resource<void>> toggleSave(String artworkId);
}
