import 'dart:async';

import 'package:artora/src/features/notifications/data/notifications_service.dart';
import 'package:artora/src/features/notifications/model/notification_model.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's inbox, kept live: it loads once, then a Realtime
/// subscription refetches it whenever a notification is created, read or
/// removed. It follows sign-in / sign-out by itself.
class NotificationsNotifier
    extends StateNotifier<RequestState<List<NotificationModel>>> {
  NotificationsNotifier(this._service) : super(const RequestInitial()) {
    _authSub = AppConfig.supabase.auth.onAuthStateChange.listen((_) {
      final uid = AppConfig.supabase.auth.currentUser?.id;
      if (uid != _uid) _start();
    });
    _start();
  }

  final NotificationsService _service;
  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _channel;
  String? _uid;
  int _requestId = 0;

  Future<void> _start() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await SBClient.instance.unsubscribeChanges(channel);
    if (!mounted) return;

    _uid = AppConfig.supabase.auth.currentUser?.id;
    final uid = _uid;
    if (uid == null) {
      state = const RequestInitial();
      return;
    }
    _channel = _service.subscribe(uid, () => unawaited(_load(silent: true)));
    await _load();
  }

  /// [silent] keeps the current list on screen while refetching.
  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    final requestId = ++_requestId;
    if (!silent || state is! RequestSuccess) state = const RequestLoading();
    final result = await _service.list();
    // A newer load (or sign-out) won; drop this one.
    if (!mounted || requestId != _requestId || _uid == null) return;
    state = result.toRequestState();
  }

  Future<void> refresh() => _load();

  /// Marks one read right away; the realtime update then confirms it.
  Future<void> markRead(String id) async {
    final current = state;
    if (current is! RequestSuccess<List<NotificationModel>>) return;
    state = RequestSuccess([
      for (final n in current.data)
        if (n.id == id) n.markedRead() else n,
    ]);
    await _service.markRead(id);
  }

  Future<void> markAllRead() async {
    final current = state;
    if (current is! RequestSuccess<List<NotificationModel>>) return;
    state = RequestSuccess([for (final n in current.data) n.markedRead()]);
    await _service.markAllRead();
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    final channel = _channel;
    if (channel != null) {
      unawaited(SBClient.instance.unsubscribeChanges(channel));
    }
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    RequestState<List<NotificationModel>>>(
  (ref) => NotificationsNotifier(const NotificationsService()),
);

/// Unread among the loaded page (the latest 50), for the bell's dot.
final unreadNotificationsProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state is RequestSuccess<List<NotificationModel>>
      ? state.data.where((n) => !n.isRead).length
      : 0;
});
