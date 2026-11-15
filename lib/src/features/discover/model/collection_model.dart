import 'package:artora/src/network/constants/supabase_buckets.dart';
import 'package:artora/src/services/supabase_storage_service.dart';
import 'package:equatable/equatable.dart';

/// A row of the `collection_cards` view (supabase/collections.sql): a collection
/// with its owner, counts and the signed-in user's like / save.
class CollectionModel extends Equatable {
  const CollectionModel({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.isPublic = false,
    this.ownerId,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerAvatarPath,
    this.artworkCount = 0,
    this.likeCount = 0,
    this.saveCount = 0,
    this.iLiked = false,
    this.iSaved = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? coverUrl;

  /// Searchable by everyone; false = only the owner sees it.
  final bool isPublic;

  /// Null for editorial collections.
  final String? ownerId;
  final String? ownerUsername;
  final String? ownerDisplayName;
  final String? ownerAvatarPath;

  final int artworkCount;
  final int likeCount;
  final int saveCount;
  final bool iLiked;
  final bool iSaved;
  final DateTime? createdAt;

  String? get ownerAvatarUrl => SupabaseStorageService.instance.publicUrl(
        SupabaseBuckets.avatars,
        ownerAvatarPath,
      );

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] as String?;
    return CollectionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      isPublic: json['is_published'] as bool? ?? false,
      ownerId: json['owner_id'] as String?,
      ownerUsername: json['owner_username'] as String?,
      ownerDisplayName: json['owner_display_name'] as String?,
      ownerAvatarPath: json['owner_avatar_path'] as String?,
      artworkCount: (json['artwork_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
      iLiked: json['i_liked'] as bool? ?? false,
      iSaved: json['i_saved'] as bool? ?? false,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        coverUrl,
        isPublic,
        ownerId,
        ownerUsername,
        ownerDisplayName,
        ownerAvatarPath,
        artworkCount,
        likeCount,
        saveCount,
        iLiked,
        iSaved,
        createdAt,
      ];
}
