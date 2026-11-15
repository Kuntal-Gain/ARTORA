import 'package:artora/src/features/notifications/model/notification_model.dart';
import 'package:artora/src/network/client/sb_client.dart';
import 'package:artora/src/network/constants/supabase_tables.dart';
import 'package:artora/src/network/resource/resource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and marks the signed-in user's notifications and listens for new ones.
/// Rows are created by database triggers, never by the app.
class NotificationsService {
  const NotificationsService();

  static const int pageSize = 50;

  // Actor, artwork (title + images) and comment text come embedded in one request.
  static const _columns = '*,'
      'actor:profiles!actor_id(id,username,display_name,avatar_path),'
      'artwork:artworks!artwork_id(title,'
      'images:artwork_images(image_url,thumbnail_url,position)),'
      'comment:comments!comment_id(content)';

  SBClient get _db => SBClient.instance;

  /// Newest first; RLS already limits this to your own.
  Future<Resource<List<NotificationModel>>> list() async {
    final result = await _db.get(
      SupabaseTables.notifications,
      columns: _columns,
      orderBy: 'created_at',
      ascending: false,
      limit: pageSize,
    );
    return result.map(
      (rows) => [
        for (final row in rows)
          if (NotificationModel.tryParse(row) case final n?) n,
      ],
    );
  }

  Future<Resource<void>> markRead(String id) async {
    final result = await _db.patch(
      SupabaseTables.notifications,
      {'read_at': DateTime.now().toUtc().toIso8601String()},
      eq: {'id': id},
    );
    return result.map<void>((_) {});
  }

  Future<Resource<void>> markAllRead() async {
    final result = await _db.patch(
      SupabaseTables.notifications,
      {'read_at': DateTime.now().toUtc().toIso8601String()},
      filter: (query) => query.isFilter('read_at', null),
    );
    return result.map<void>((_) {});
  }

  /// Calls [onChange] for every insert / update / delete of [userId]'s
  /// notifications. Remove it with [SBClient.unsubscribeChanges].
  RealtimeChannel subscribe(String userId, void Function() onChange) {
    return _db.subscribeChanges(
      SupabaseTables.notifications,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'recipient_id',
        value: userId,
      ),
      onChange: (_) => onChange(),
    );
  }
}
