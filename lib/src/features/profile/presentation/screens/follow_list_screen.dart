import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/discover/model/follow_model.dart';
import 'package:artora/src/features/discover/presentation/providers/block_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/follow_button.dart';
import 'package:artora/src/features/discover/presentation/widgets/underline_tabs.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/shared/widgets/navigation/artora_bottom_nav.dart';

enum FollowListTab { followers, following }

/// An artist's followers and the people they follow: two tabs, a search box
/// and a list with Follow / Follow Back / Following buttons.
class FollowListScreen extends ConsumerStatefulWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    this.initialTab = FollowListTab.followers,
  });

  final String userId;
  final FollowListTab initialTab;

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  late FollowListTab _tab = widget.initialTab;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(FollowUserModel u) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return u.username.toLowerCase().contains(q) ||
        u.displayName.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.userId;
    final followers = ref.watch(followersProvider(id));
    final followings = ref.watch(followingsProvider(id));
    final profile = ref.watch(userProfileProvider(id)).value;

    int? length(RequestState<List<FollowUserModel>> s) =>
        s is RequestSuccess<List<FollowUserModel>> ? s.data.length : null;
    final followersCount = profile?.totalFollowers ?? length(followers) ?? 0;
    final followingCount = profile?.totalFollowings ?? length(followings) ?? 0;

    final active = _tab == FollowListTab.followers ? followers : followings;
    final notifier = _tab == FollowListTab.followers
        ? ref.read(followersProvider(id).notifier)
        : ref.read(followingsProvider(id).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: ArtoraBottomNav(
        currentIndex: null,
        onSelected: (index) => context.go(ArtoraBottomNav.tabPaths[index]),
        onCreate: ArtoraBottomNav.showCreateComingSoon,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.artistProfilePath(id)),
        ),
        title: Text(
          LocaleKeys.follow_list_title.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: UnderlineTabs(
              labels: [
                LocaleKeys.follow_list_tab_followers.tr(
                  namedArgs: {'count': formatCompact(followersCount)},
                ),
                LocaleKeys.follow_list_tab_following.tr(
                  namedArgs: {'count': formatCompact(followingCount)},
                ),
              ],
              selectedIndex: _tab.index,
              onSelected: (i) => setState(() => _tab = FollowListTab.values[i]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: AppSearchField(
              controller: _search,
              hint: LocaleKeys.follow_list_search_hint.tr(),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: switch (active) {
              RequestInitial() || RequestLoading() => const AppLoading(),
              RequestFailure(:final failure) => AppErrorWidget(
                  message: failure.message,
                  onRetry: notifier.refresh,
                ),
              RequestSuccess(:final data) => _list(
                  context,
                  data.where(_matches).toList(),
                  empty: data.isEmpty,
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<FollowUserModel> users, {
    required bool empty,
  }) {
    if (users.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.people,
        title: (empty
                ? (_tab == FollowListTab.followers
                    ? LocaleKeys.follow_list_empty_followers
                    : LocaleKeys.follow_list_empty_following)
                : LocaleKeys.follow_list_no_match)
            .tr(),
      );
    }
    final me = AppConfig.supabase.auth.currentUser?.id;
    final blocked = ref.watch(blockedIdsProvider);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        MediaQuery.paddingOf(context).bottom + 100.r,
      ),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        return _UserRow(
          user: user,
          blocked: blocked.contains(user.id),
          // Nothing to follow on your own row.
          button: user.id == me
              ? null
              : FollowButton(
                  userId: user.id,
                  followsMe: user.followsMe,
                  width: 112.w,
                ),
          onTap: () => context.push(AppRoutes.artistProfilePath(user.id)),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onTap,
    this.button,
    this.blocked = false,
  });

  final FollowUserModel user;
  final VoidCallback onTap;
  final Widget? button;

  /// You blocked them: a "Blocked" chip sits beside the name.
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final bio = user.bio?.trim() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.md,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: user.avatarUrl,
              initials: user.displayName,
              radius: 28,
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (blocked) ...[
                        AppSpacing.hGap(AppSpacing.sm),
                        const AppBlockedChip(),
                      ],
                    ],
                  ),
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (button != null) ...[
              AppSpacing.hGap(AppSpacing.sm),
              button!,
            ],
          ],
        ),
      ),
    );
  }
}

