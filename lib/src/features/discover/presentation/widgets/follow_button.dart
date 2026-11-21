import 'package:artora/src/features/discover/presentation/providers/block_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
import 'package:artora/src/imports/imports.dart';

/// [AppFollowButton] wired to the follow providers: live Following state,
/// Loading while the request runs, and Follow Back when [followsMe]. For
/// someone you blocked it is an Unblock button instead.
class FollowButton extends ConsumerWidget {
  const FollowButton({
    super.key,
    required this.userId,
    this.followsMe = false,
    this.height = ButtonSize.small,
    this.width,
  });

  final String userId;
  final bool followsMe;
  final ButtonSize height;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked =
        ref.watch(blockedIdsProvider.select((ids) => ids.contains(userId)));
    if (isBlocked) {
      return SizedBox(
        width: width,
        child: AppButton(
          label: LocaleKeys.block_unblock.tr(),
          variant: ButtonVariant.outline,
          height: height,
          onPressed: () => unblockWithToast(ref, userId),
        ),
      );
    }

    final isFollowing =
        ref.watch(followingProvider.select((ids) => ids.contains(userId)));
    final isLoading =
        ref.watch(followPendingProvider.select((ids) => ids.contains(userId)));

    return AppFollowButton(
      isFollowing: isFollowing,
      followsMe: followsMe,
      isLoading: isLoading,
      height: height,
      width: width,
      onPressed: () => ref.read(followActionsProvider).toggle(userId),
    );
  }
}
