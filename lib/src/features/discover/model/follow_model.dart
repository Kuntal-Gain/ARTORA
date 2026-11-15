import 'package:artora/src/network/constants/supabase_buckets.dart';
import 'package:artora/src/services/supabase_storage_service.dart';
import 'package:equatable/equatable.dart';

/// One person in a followers / following list.
///
/// [iFollow] and [followsMe] are relative to the signed-in user (not to whose
/// list it is), so the UI can pick the right button:
/// - neither            -> Follow
/// - [iFollow]          -> Following
/// - only [followsMe]   -> Follow Back
class FollowUserModel extends Equatable {
  const FollowUserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarPath,
    this.followedAt,
    this.iFollow = false,
    this.followsMe = false,
  });

  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarPath;

  /// When the follow in this list was created.
  final DateTime? followedAt;

  final bool iFollow;
  final bool followsMe;

  /// Both follow each other.
  bool get isMutual => iFollow && followsMe;

  /// They follow me and I haven't followed them back yet.
  bool get canFollowBack => followsMe && !iFollow;

  String? get avatarUrl => SupabaseStorageService.instance.publicUrl(
        SupabaseBuckets.avatars,
        avatarPath,
      );

  /// A row from `list_followers` / `list_following`.
  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    final followedAt = json['followed_at'] as String?;
    return FollowUserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarPath: json['avatar_path'] as String?,
      followedAt: followedAt == null ? null : DateTime.tryParse(followedAt),
      iFollow: json['i_follow'] as bool? ?? false,
      followsMe: json['follows_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'bio': bio,
        'avatar_path': avatarPath,
        'followed_at': followedAt?.toIso8601String(),
        'i_follow': iFollow,
        'follows_me': followsMe,
      };

  FollowUserModel copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarPath,
    DateTime? followedAt,
    bool? iFollow,
    bool? followsMe,
  }) {
    return FollowUserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      followedAt: followedAt ?? this.followedAt,
      iFollow: iFollow ?? this.iFollow,
      followsMe: followsMe ?? this.followsMe,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        bio,
        avatarPath,
        followedAt,
        iFollow,
        followsMe,
      ];
}
