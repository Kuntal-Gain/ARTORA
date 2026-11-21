import 'package:artora/src/network/constants/supabase_buckets.dart';
import 'package:artora/src/services/supabase_storage_service.dart';
import 'package:equatable/equatable.dart';

/// Someone the signed-in user blocked, from `list_blocked_users`
/// (supabase/blocks.sql).
class BlockedUserModel extends Equatable {
  const BlockedUserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarPath,
    this.blockedAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarPath;
  final DateTime? blockedAt;

  String? get avatarUrl => SupabaseStorageService.instance.publicUrl(
        SupabaseBuckets.avatars,
        avatarPath,
      );

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    final blockedAt = json['blocked_at'] as String?;
    return BlockedUserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarPath: json['avatar_path'] as String?,
      blockedAt: blockedAt == null ? null : DateTime.tryParse(blockedAt),
    );
  }

  @override
  List<Object?> get props => [id, username, displayName, avatarPath, blockedAt];
}
