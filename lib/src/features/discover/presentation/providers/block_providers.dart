import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/discover/model/blocked_user_model.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/imports/imports.dart';

/// People the signed-in user blocked, with their profile (Blocked Users
/// screen). Errors carry the failure message.
final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUserModel>>((ref) async {
  final result = await ref.watch(discoverUsecaseProvider).getBlockedUsers();
  return switch (result) {
    ResourceSuccess<List<BlockedUserModel>>(:final data) => data,
    ResourceError<List<BlockedUserModel>>(:final failure) =>
      throw failure.message,
    ResourceLoading<List<BlockedUserModel>>() => const <BlockedUserModel>[],
  };
});

/// Unblocks [userId] from any screen and says so; on a server refusal the
/// provider rolls back and shows the error itself, so no toast follows.
Future<void> unblockWithToast(WidgetRef ref, String userId) async {
  await ref.read(blockedIdsProvider.notifier).toggle(userId);
  if (!ref.read(blockedIdsProvider).contains(userId)) {
    showGlobalToast(message: LocaleKeys.block_user_unblocked.tr());
  }
}

/// Ids the signed-in user blocked. The change shows instantly and is rolled
/// back with an error toast if the server refuses it, so a profile can switch
/// between Block and Unblock without waiting. Call
/// `ref.read(blockedIdsProvider.notifier).toggle(id)`.
final blockedIdsProvider =
    StateNotifierProvider<ToggleSetNotifier, Set<String>>((ref) {
  final usecase = ref.watch(discoverUsecaseProvider);
  return ToggleSetNotifier(
    (id, on) async {
      final result =
          await (on ? usecase.blockUser(id) : usecase.unblockUser(id));
      if (result is ResourceSuccess<void>) {
        // A block (or unblock) changes the blocked list, the feeds, explore,
        // saved, who I follow and profile data. These refresh in place, so
        // what is on screen stays until the new data arrives.
        ref.invalidate(blockedUsersProvider);
        ref.invalidate(followingFeedProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(currentUserProvider);
        ref.read(feedProvider.notifier).refresh();
        ref.read(exploreProvider.notifier).refresh();
        ref.read(savedArtworksProvider.notifier).refresh();
        ref.read(followingProvider.notifier).reload();
      }
      return result;
    },
    load: () async => (await usecase.getBlockedUsers())
        .map((list) => list.map((user) => user.id).toSet()),
  );
});
