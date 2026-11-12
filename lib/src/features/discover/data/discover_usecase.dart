import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/features/discover/model/comment_model.dart';
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

  /// a single [ARTWORK] with its artist's profile embedded
  Future<Resource<ArtworkModel>> fetchPostById(String postId);

  /// top-level comments of an artwork, with reply and like counts
  Future<Resource<List<CommentModel>>> fetchComments(
    String artworkId, {
    bool newestFirst = true,
  });

  /// like/unlike a comment or reply
  Future<Resource<void>> toggleCommentLike(String commentId);

  /// replies of one comment, oldest first
  Future<Resource<List<CommentModel>>> fetchReplies(String commentId);

  /// post a comment, or a reply when [parentId] is given
  Future<Resource<void>> postComment(
    String artworkId,
    String content, {
    String? parentId,
  });

  /// delete a comment (and its replies); RLS limits this to the author or
  /// the artwork owner
  Future<Resource<void>> deleteComment(String commentId);

  /// delete a [Artwork] from the platform
  Future<Resource<void>> deleteArtwork(String artworkId);

  /// like/unlike a [Artwork]
  Future<Resource<void>> toggleLike(String artworkId);

  /// save/unsave a [Artwork]
  Future<Resource<void>> toggleSave(String artworkId);
}
