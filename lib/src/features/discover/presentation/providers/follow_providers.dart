import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/discover/model/follow_model.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/imports/imports.dart';

// All follow state lives here, split by job:
//  - [followingProvider]: the ids the signed-in user follows. Drives every
//    Follow button instantly (optimistic).
//  - [followersProvider] / [followingsProvider]: the lists, per user id.
//  - [followActionsProvider]: followUser / unfollowUser, which also keep the
//    lists fresh.
//
// List rows carry `iFollow` / `followsMe` from when they were fetched. To keep a
// row's button live, read `ref.watch(followingProvider).contains(id)` for "I
// follow them" and use the row's `followsMe` for the Follow Back label.

// ── WHO I FOLLOW ────────────────────────────────────────────

/// Ids the signed-in user follows; [ToggleSetNotifier.toggle] follows or
/// unfollows with an instant flip and rolls back on failure.
final followingProvider =
    StateNotifierProvider<ToggleSetNotifier, Set<String>>((ref) {
  final usecase = ref.watch(discoverUsecaseProvider);
  return ToggleSetNotifier(
    (id, on) => on ? usecase.followUser(id) : usecase.unfollowUser(id),
    load: usecase.getFollowingIds,
  );
});

// ── FOLLOWERS ───────────────────────────────────────────────

/// People who follow [userId] (needs supabase/follows.sql).
final followersProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<List<FollowUserModel>>,
    RequestState<List<FollowUserModel>>,
    String>(
  (ref, userId) {
    final usecase = ref.watch(discoverUsecaseProvider);
    return DiscoverFetchNotifier(() => usecase.getFollowers(userId));
  },
);

// ── FOLLOWING ───────────────────────────────────────────────

/// People [userId] follows (needs supabase/follows.sql).
final followingsProvider = StateNotifierProvider.autoDispose.family<
    DiscoverFetchNotifier<List<FollowUserModel>>,
    RequestState<List<FollowUserModel>>,
    String>(
  (ref, userId) {
    final usecase = ref.watch(discoverUsecaseProvider);
    return DiscoverFetchNotifier(() => usecase.getFollowings(userId));
  },
);

// ── FOLLOW / UNFOLLOW ───────────────────────────────────────

/// Follow or unfollow someone.
///
/// The button flips immediately and rolls back with an error toast if the
/// request fails (done by [followingProvider]). The follower / following lists
/// are not reloaded (that would flash a spinner); their buttons follow
/// [followingProvider] and the lists refetch the next time they are opened.
/// The profile counts are refreshed, keeping the old numbers while they reload.
class FollowActions {
  const FollowActions(this._ref);

  final Ref _ref;

  /// No-op if you already follow [userId].
  Future<void> followUser(String userId) async {
    if (_ref.read(followingProvider).contains(userId)) return;
    await _ref.read(followingProvider.notifier).toggle(userId);
    _refreshCounts();
  }

  /// No-op if you don't follow [userId]. Their follow of you is untouched, so
  /// they stay your follower and you get a Follow Back option again.
  Future<void> unfollowUser(String userId) async {
    if (!_ref.read(followingProvider).contains(userId)) return;
    await _ref.read(followingProvider.notifier).toggle(userId);
    _refreshCounts();
  }

  void _refreshCounts() {
    _ref
      ..invalidate(userProfileProvider)
      ..invalidate(currentUserProvider);
  }
}

final followActionsProvider = Provider<FollowActions>(FollowActions.new);
