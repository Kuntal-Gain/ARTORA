import 'dart:io';

import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/features/discover/model/collection_model.dart';
import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/model/follow_model.dart';
import 'package:artora/src/imports/imports.dart';

abstract class DiscoverUsecase {
  // ═══════════════════════════════════════════════════════════
  // FEED — home feed, profile feeds, liked and saved lists
  // ═══════════════════════════════════════════════════════════

  /// get [public] feed
  Future<Resource<ArtworkListModel>> getPublicFeed();

  /// get [user] feed
  Future<Resource<ArtworkListModel>> getUserFeed(String uid);

  /// get [user] liked artworks
  Future<Resource<ArtworkListModel>> getUserLikedArtworks(String uid);

  /// get [user] saved artworks
  Future<Resource<ArtworkListModel>> getUserSavedArtworks(String uid);

  // ═══════════════════════════════════════════════════════════
  // EXPLORE — categories, trending tags, collections, artists, picks
  // ═══════════════════════════════════════════════════════════

  /// everything the explore screen shows, in one call (`get_explore` RPC);
  /// [category] narrows the artists and editor's picks, null means all
  Future<Resource<ExploreContent>> fetchExplore({String? category});

  // ═══════════════════════════════════════════════════════════
  // SEARCH & FOLLOWS — artwork / artist / tag search, who the user follows
  // ═══════════════════════════════════════════════════════════

  /// public artworks, artists and tags matching [query]
  Future<Resource<SearchResults>> search(String query);

  /// ids of the artists the signed-in user follows
  Future<Resource<Set<String>>> getFollowingIds();

  /// follow or unfollow an artist; safe to repeat
  Future<Resource<void>> setFollowing(
    String artistId, {
    required bool following,
  });

  /// follow [userId] (one-way; they get a Follow Back option); safe to repeat
  Future<Resource<void>> followUser(String userId);

  /// stop following [userId]; safe to repeat. Their follow of you stays.
  Future<Resource<void>> unfollowUser(String userId);

  /// people who follow [userId], newest first (needs supabase/follows.sql)
  Future<Resource<List<FollowUserModel>>> getFollowers(
    String userId, {
    int limit = 50,
    int offset = 0,
  });

  /// people [userId] follows, newest first (needs supabase/follows.sql)
  Future<Resource<List<FollowUserModel>>> getFollowings(
    String userId, {
    int limit = 50,
    int offset = 0,
  });

  // ═══════════════════════════════════════════════════════════
  // ARTWORK — create, read, update, delete, like, save
  // ═══════════════════════════════════════════════════════════

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

  /// delete a [Artwork] from the platform
  Future<Resource<void>> deleteArtwork(String artworkId);

  /// like/unlike a [Artwork]
  Future<Resource<void>> toggleLike(String artworkId);

  /// save/unsave a [Artwork]
  Future<Resource<void>> toggleSave(String artworkId);

  // ═══════════════════════════════════════════════════════════
  // COLLECTIONS — owner-made folders of artworks (needs supabase/collections.sql)
  // ═══════════════════════════════════════════════════════════

  /// create a collection owned by the signed-in user with an optional [cover]
  /// image and [artworkIds] in that order; returns its id. Private unless
  /// [isPublic].
  Future<Resource<String>> createCollection(
    String title, {
    String? description,
    bool isPublic = false,
    File? cover,
    List<String> artworkIds = const [],
  });

  /// add an artwork to your own collection; safe to repeat
  Future<Resource<void>> addToCollection(
    String collectionId,
    String artworkId,
  );

  /// remove an artwork from your own collection
  Future<Resource<void>> removeFromCollection(
    String collectionId,
    String artworkId,
  );

  /// delete your own collection (its artworks are not deleted)
  Future<Resource<void>> deleteCollection(String collectionId);

  /// collections owned by [userId]; private ones only show for yourself
  Future<Resource<List<CollectionModel>>> getUserCollections(
    String userId, {
    int limit = 20,
    int offset = 0,
  });

  /// public collections whose title matches [query]
  Future<Resource<List<CollectionModel>>> searchCollections(
    String query, {
    int limit = 20,
    int offset = 0,
  });

  /// public collections with the most recent likes and saves (`trending_collections` RPC)
  Future<Resource<List<CollectionModel>>> getTrendingCollections({
    int limit = 20,
    int offset = 0,
  });

  // ═══════════════════════════════════════════════════════════
  // COMMENTS — threads, replies, likes
  // ═══════════════════════════════════════════════════════════

  /// top-level comments of an artwork, with reply and like counts
  Future<Resource<List<CommentModel>>> fetchComments(
    String artworkId, {
    bool newestFirst = true,
  });

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

  /// like/unlike a comment or reply
  Future<Resource<void>> toggleCommentLike(String commentId);
}
