import 'package:artora/src/network/constants/supabase_buckets.dart';
import 'package:artora/src/services/supabase_storage_service.dart';
import 'package:equatable/equatable.dart';

/// What happened. Created by database triggers (supabase/notifications.sql).
enum NotificationType {
  like,
  comment,
  follow;

  static NotificationType? parse(String? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

/// One row of the signed-in user's inbox, with who did it and which artwork.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.createdAt,
    this.actorUsername = '',
    this.actorDisplayName = '',
    this.actorAvatarPath,
    this.artworkId,
    this.artworkTitle,
    this.artworkThumbUrl,
    this.commentText,
    this.readAt,
  });

  final String id;
  final NotificationType type;
  final String actorId;
  final String actorUsername;
  final String actorDisplayName;
  final String? actorAvatarPath;

  /// Set for [NotificationType.like] and [NotificationType.comment].
  final String? artworkId;
  final String? artworkTitle;

  /// First image of the artwork, shown on the right of the row.
  final String? artworkThumbUrl;

  /// What was written, for [NotificationType.comment].
  final String? commentText;

  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  /// Name to show: the display name, else the username.
  String get actorName =>
      actorDisplayName.trim().isEmpty ? actorUsername : actorDisplayName;

  String? get actorAvatarUrl => SupabaseStorageService.instance.publicUrl(
        SupabaseBuckets.avatars,
        actorAvatarPath,
      );

  /// A row of `notifications` with `actor:profiles(...)` and
  /// `artwork:artworks(title)` embedded. Null for an unknown type, so a newer
  /// server type never breaks an older app.
  static NotificationModel? tryParse(Map<String, dynamic> json) {
    final type = NotificationType.parse(json['type'] as String?);
    if (type == null) return null;
    final actor = json['actor'] as Map<String, dynamic>? ?? const {};
    final artwork = json['artwork'] as Map<String, dynamic>? ?? const {};
    final comment = json['comment'] as Map<String, dynamic>? ?? const {};
    final readAt = json['read_at'] as String?;

    // First image by position; thumbnail, else the full image.
    final images = [
      for (final i in artwork['images'] as List<dynamic>? ?? const [])
        if (i is Map<String, dynamic>) i,
    ]..sort(
        (a, b) => ((a['position'] as num?) ?? 0)
            .compareTo((b['position'] as num?) ?? 0),
      );
    final thumb = images.isEmpty
        ? null
        : (images.first['thumbnail_url'] ?? images.first['image_url'])
            as String?;
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: type,
      actorId: json['actor_id'] as String? ?? actor['id'] as String? ?? '',
      actorUsername: actor['username'] as String? ?? '',
      actorDisplayName: actor['display_name'] as String? ?? '',
      actorAvatarPath: actor['avatar_path'] as String?,
      artworkId: json['artwork_id'] as String?,
      artworkTitle: artwork['title'] as String?,
      artworkThumbUrl: thumb,
      commentText: comment['content'] as String?,
      readAt: readAt == null ? null : DateTime.tryParse(readAt),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  NotificationModel markedRead() => NotificationModel(
        id: id,
        type: type,
        actorId: actorId,
        createdAt: createdAt,
        actorUsername: actorUsername,
        actorDisplayName: actorDisplayName,
        actorAvatarPath: actorAvatarPath,
        artworkId: artworkId,
        artworkTitle: artworkTitle,
        artworkThumbUrl: artworkThumbUrl,
        commentText: commentText,
        readAt: readAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        type,
        actorId,
        actorUsername,
        actorDisplayName,
        actorAvatarPath,
        artworkId,
        artworkTitle,
        artworkThumbUrl,
        commentText,
        readAt,
        createdAt,
      ];
}
