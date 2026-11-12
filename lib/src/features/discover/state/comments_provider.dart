import 'package:artora/src/features/discover/data/discover_usecase.dart';
import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent, PostgresChangeFilter, PostgresChangeFilterType;

class CommentsState {
  const CommentsState({
    this.comments = const [],
    this.replies = const {},
    this.newestFirst = true,
  });

  /// Top-level comments in the chosen order.
  final List<CommentModel> comments;

  /// Loaded replies by parent id. A key means that thread is expanded.
  final Map<String, List<CommentModel>> replies;

  final bool newestFirst;

  /// Comments plus all their replies, from the server's per-comment counts.
  int get total => comments.fold(0, (sum, c) => sum + 1 + c.repliesCount);

  CommentsState copyWith({
    List<CommentModel>? comments,
    Map<String, List<CommentModel>>? replies,
    bool? newestFirst,
  }) =>
      CommentsState(
        comments: comments ?? this.comments,
        replies: replies ?? this.replies,
        newestFirst: newestFirst ?? this.newestFirst,
      );
}

class CommentsNotifier extends StateNotifier<RequestState<CommentsState>> {
  CommentsNotifier(this._usecase, this._artworkId)
      : super(const RequestLoading()) {
    refresh();
  }

  final DiscoverUsecase _usecase;
  final String _artworkId;
  bool _newestFirst = true;

  CommentsState get _data => switch (state) {
        RequestSuccess(:final data) => data,
        _ => CommentsState(newestFirst: _newestFirst),
      };

  void _emit(CommentsState data) => state = RequestSuccess(data);

  /// Reloads the top-level list and every expanded thread. Keeps showing the
  /// current data meanwhile, so live updates don't flash a spinner.
  Future<void> refresh() async {
    try {
      await _refresh();
    } catch (error, stack) {
      // Never leave the screen on a spinner; show what went wrong.
      debugPrint('[COMMENTS] refresh failed: $error\n$stack');
      if (mounted && state is! RequestSuccess<CommentsState>) {
        state = RequestFailure(UnknownFailure(error.toString()));
      }
    }
  }

  Future<void> _refresh() async {
    final newestFirst = _newestFirst;
    final result = await _usecase.fetchComments(
      _artworkId,
      newestFirst: newestFirst,
    );
    if (!mounted || newestFirst != _newestFirst) return; // sort changed
    if (result case ResourceError(:final failure)) {
      // A failed live reload shouldn't wipe what's already on screen.
      if (state is! RequestSuccess<CommentsState>) {
        state = RequestFailure(failure);
      }
      return;
    }
    final comments = result.dataOrNull ?? const <CommentModel>[];
    final replies = <String, List<CommentModel>>{};
    for (final parentId in _data.replies.keys) {
      if (!comments.any((c) => c.id == parentId)) continue; // parent deleted
      final loaded = (await _usecase.fetchReplies(parentId)).dataOrNull;
      replies[parentId] = loaded ?? _data.replies[parentId] ?? const [];
    }
    if (!mounted) return;
    _emit(
      CommentsState(
        comments: comments,
        replies: replies,
        newestFirst: newestFirst,
      ),
    );
  }

  Future<void> setNewestFirst(bool value) async {
    if (value == _newestFirst) return;
    _newestFirst = value;
    _emit(_data.copyWith(newestFirst: value));
    await refresh();
  }

  Future<void> toggleReplies(String commentId) async {
    final data = _data;
    if (data.replies.containsKey(commentId)) {
      _emit(data.copyWith(replies: {...data.replies}..remove(commentId)));
      return;
    }
    final loaded = (await _usecase.fetchReplies(commentId)).dataOrNull;
    if (!mounted || loaded == null) return;
    _emit(_data.copyWith(replies: {..._data.replies, commentId: loaded}));
  }

  /// Heart and count flip instantly; rolled back if the server refuses.
  Future<void> toggleLike(String commentId) async {
    _flipLike(commentId);
    final result = await _usecase.toggleCommentLike(commentId);
    if (!mounted) return;
    if (result case ResourceError(:final failure)) {
      _flipLike(commentId);
      showGlobalToast(message: failure.message, status: 'error');
    }
  }

  /// A like added/removed by someone else (realtime). Ignored for comments
  /// that aren't on screen, which also filters out other artworks' likes.
  void bumpLikes(String commentId, int delta) {
    List<CommentModel> bump(List<CommentModel> list) => [
          for (final c in list) c.id == commentId ? c.withLikesDelta(delta) : c,
        ];
    final data = _data;
    _emit(
      data.copyWith(
        comments: bump(data.comments),
        replies: {
          for (final e in data.replies.entries) e.key: bump(e.value),
        },
      ),
    );
  }

  void _flipLike(String commentId) {
    List<CommentModel> flip(List<CommentModel> list) => [
          for (final c in list) c.id == commentId ? c.toggledLike() : c,
        ];
    final data = _data;
    _emit(
      data.copyWith(
        comments: flip(data.comments),
        replies: {
          for (final e in data.replies.entries) e.key: flip(e.value),
        },
      ),
    );
  }

  /// Returns whether it was posted; failures are toasted here.
  Future<bool> post(String content, {String? parentId}) async {
    final result = await _usecase.postComment(
      _artworkId,
      content,
      parentId: parentId,
    );
    if (result case ResourceError(:final failure)) {
      showGlobalToast(message: failure.message, status: 'error');
      return false;
    }
    if (parentId != null && !_data.replies.containsKey(parentId)) {
      await toggleReplies(parentId); // show the reply the user just wrote
    }
    await refresh();
    return true;
  }

  Future<void> delete(String commentId) async {
    final result = await _usecase.deleteComment(commentId);
    if (result case ResourceError(:final failure)) {
      showGlobalToast(message: failure.message, status: 'error');
      return;
    }
    await refresh();
  }
}

final commentsProvider = StateNotifierProvider.autoDispose
    .family<CommentsNotifier, RequestState<CommentsState>, String>(
  (ref, artworkId) {
    final notifier = CommentsNotifier(
      ref.watch(discoverUsecaseProvider),
      artworkId,
    );

    // Keep the feed tile's comment count in step with this thread.
    notifier.addListener((state) {
      if (state case RequestSuccess<CommentsState>(:final data)) {
        ref.read(feedProvider.notifier).mutate((list) => [
              for (final a in list)
                a.id == artworkId ? a.withComments(data.total) : a,
            ]);
      }
    });

    // Live comments. Needs `comments` in the supabase_realtime publication
    // (see supabase/comments.sql).
    final channel = SBClient.instance.subscribeChanges(
      'comments',
      event: PostgresChangeEvent.all,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'artwork_id',
        value: artworkId,
      ),
      onStatus: (status, error) =>
          debugPrint('[REALTIME] comments status: $status $error'),
      onChange: (payload) {
        // DELETE events ignore the filter above, so check the artwork here.
        final record = payload.eventType == PostgresChangeEvent.delete
            ? payload.oldRecord
            : payload.newRecord;
        if (record['artwork_id'] != artworkId) return;
        // Our own changes already reloaded the list when they finished.
        if (record['user_id'] == AppConfig.supabase.auth.currentUser?.id) {
          return;
        }
        notifier.refresh();
      },
    );
    ref.onDispose(() => SBClient.instance.unsubscribeChanges(channel));

    // Live comment likes. comment_likes has no artwork_id to filter on, so
    // bumpLikes ignores comments this screen doesn't show. Needs the table in
    // the publication with REPLICA IDENTITY FULL (see supabase/comments.sql).
    final likesChannel = SBClient.instance.subscribeChanges(
      'comment_likes',
      event: PostgresChangeEvent.all,
      onStatus: (status, error) =>
          debugPrint('[REALTIME] comment_likes status: $status $error'),
      onChange: (payload) {
        final isInsert = payload.eventType == PostgresChangeEvent.insert;
        if (!isInsert && payload.eventType != PostgresChangeEvent.delete) {
          return;
        }
        final record = isInsert ? payload.newRecord : payload.oldRecord;
        final id = record['comment_id'] as String?;
        if (id == null) return;
        // Our own like is already counted optimistically.
        if (record['user_id'] == AppConfig.supabase.auth.currentUser?.id) {
          return;
        }
        notifier.bumpLikes(id, isInsert ? 1 : -1);
      },
    );
    ref.onDispose(() => SBClient.instance.unsubscribeChanges(likesChannel));
    return notifier;
  },
);
