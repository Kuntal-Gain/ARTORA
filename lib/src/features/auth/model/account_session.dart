/// One signed-in device, from `list_my_sessions` (supabase/account.sql).
class AccountSession {
  const AccountSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.isCurrent,
    this.userAgent,
    this.ip,
  });

  final String id;
  final DateTime createdAt;

  /// Last time this session was used or refreshed.
  final DateTime updatedAt;

  /// The session of the device that's looking at the list.
  final bool isCurrent;
  final String? userAgent;
  final String? ip;

  factory AccountSession.fromJson(Map<String, dynamic> json) {
    final created = DateTime.parse(json['created_at'] as String).toLocal();
    final updated = json['updated_at'] as String?;
    return AccountSession(
      id: json['id'] as String,
      createdAt: created,
      updatedAt: updated == null ? created : DateTime.parse(updated).toLocal(),
      isCurrent: json['is_current'] as bool? ?? false,
      userAgent: json['user_agent'] as String?,
      ip: json['ip'] as String?,
    );
  }
}
