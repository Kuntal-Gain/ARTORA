import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:equatable/equatable.dart';

/// A comment, or a reply to one when [parentId] is set (one level only).
class CommentModel extends Equatable {
  const CommentModel({
    required this.id,
    required this.artworkId,
    required this.userId,
    required this.content,
    this.parentId,
    this.author,
    this.repliesCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
    this.createdAt,
  });

  final String id;
  final String artworkId;
  final String userId;
  final String? parentId;
  final String content;
  final ArtworkArtistModel? author;
  final int repliesCount;
  final int likesCount;
  final bool isLiked;
  final DateTime? createdAt;

  bool get isReply => parentId != null;

  /// Same comment with [delta] added to the like count (someone else's like).
  CommentModel withLikesDelta(int delta) => CommentModel(
        id: id,
        artworkId: artworkId,
        userId: userId,
        parentId: parentId,
        content: content,
        author: author,
        repliesCount: repliesCount,
        likesCount: (likesCount + delta).clamp(0, 1 << 31),
        isLiked: isLiked,
        createdAt: createdAt,
      );

  /// Flips the viewer's like, adjusting the count (used optimistically).
  CommentModel toggledLike() => CommentModel(
        id: id,
        artworkId: artworkId,
        userId: userId,
        parentId: parentId,
        content: content,
        author: author,
        repliesCount: repliesCount,
        likesCount: (likesCount + (isLiked ? -1 : 1)).clamp(0, 1 << 31),
        isLiked: !isLiked,
        createdAt: createdAt,
      );

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String? ?? '',
      artworkId: json['artwork_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      content: json['content'] as String? ?? '',
      author: json['profile'] is Map<String, dynamic>
          ? ArtworkArtistModel.fromJson(
              json['profile'] as Map<String, dynamic>,
            )
          : null,
      // PostgREST embeds an aggregate as [{count: n}].
      repliesCount: switch (json['replies_count']) {
        [{'count': final num n}, ...] => n.toInt(),
        _ => 0,
      },
      likesCount: switch (json['likes_count']) {
        [{'count': final num n}, ...] => n.toInt(),
        _ => 0,
      },
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
        id,
        artworkId,
        userId,
        parentId,
        content,
        author,
        repliesCount,
        likesCount,
        isLiked,
        createdAt,
      ];
}
