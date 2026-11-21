import 'package:artora/src/features/discover/model/blocked_user_model.dart';
import 'package:artora/src/features/discover/presentation/providers/block_providers.dart';
import 'package:artora/src/imports/imports.dart';

/// People the signed-in user blocked, each with an Unblock button. Tapping a
/// row opens their profile.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  /// Rows already unblocked here: they leave the list at once, before the
  /// reloaded list arrives.
  final Set<String> _unblocked = {};

  Future<void> _unblock(BlockedUserModel user) async {
    setState(() => _unblocked.add(user.id));
    await ref.read(blockedIdsProvider.notifier).toggle(user.id);
    if (!mounted) return;
    // The provider rolls back and toasts when the server refuses; bring the
    // row back in that case.
    if (ref.read(blockedIdsProvider).contains(user.id)) {
      setState(() => _unblocked.remove(user.id));
    } else {
      showGlobalToast(message: LocaleKeys.block_user_unblocked.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.settings),
        ),
        title: Text(
          LocaleKeys.settings_blocked_users.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: switch (blocked) {
        // Keep the list on screen while it reloads after an unblock.
        AsyncValue(:final value?) => _list(
            context,
            value.where((u) => !_unblocked.contains(u.id)).toList(),
          ),
        AsyncError() => AppErrorWidget(
            message: LocaleKeys.block_load_failed.tr(),
            onRetry: () => ref.invalidate(blockedUsersProvider),
          ),
        _ => const AppLoading(),
      },
    );
  }

  Widget _list(BuildContext context, List<BlockedUserModel> users) {
    if (users.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.block,
        title: LocaleKeys.block_none_title.tr(),
        subtitle: LocaleKeys.block_none_subtitle.tr(),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      itemCount: users.length,
      separatorBuilder: (_, __) => AppSpacing.vGap(AppSpacing.xs),
      itemBuilder: (context, i) {
        final user = users[i];
        return _BlockedRow(
          user: user,
          onOpen: () => context.push(AppRoutes.artistProfilePath(user.id)),
          onUnblock: () => _unblock(user),
        );
      },
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({
    required this.user,
    required this.onOpen,
    required this.onUnblock,
  });

  final BlockedUserModel user;
  final VoidCallback onOpen;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colors;

    return InkWell(
      onTap: onOpen,
      borderRadius: AppBorders.md,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: user.avatarUrl,
              initials: user.displayName,
              radius: 26,
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            AppButton(
              label: LocaleKeys.block_unblock.tr(),
              variant: ButtonVariant.outline,
              height: ButtonSize.small,
              onPressed: onUnblock,
            ),
          ],
        ),
      ),
    );
  }
}
