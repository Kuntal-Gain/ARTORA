import 'package:artora/src/features/discover/presentation/widgets/follow_button.dart';
import 'package:artora/src/features/notifications/model/notification_model.dart';
import 'package:artora/src/features/notifications/presentation/providers/notification_providers.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/shared/widgets/navigation/artora_bottom_nav.dart';

enum _Filter { all, likes, comments, follows }

/// "Activity": likes, comments and new followers grouped by day, with a filter
/// row. New ones appear by themselves (see [notificationsProvider]).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _Filter _filter = _Filter.all;

  bool _matches(NotificationModel n) => switch (_filter) {
        _Filter.all => true,
        _Filter.likes => n.type == NotificationType.like,
        _Filter.comments => n.type == NotificationType.comment,
        _Filter.follows => n.type == NotificationType.follow,
      };

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.all => LocaleKeys.discover_all,
        _Filter.likes => LocaleKeys.notifications_filter_likes,
        _Filter.comments => LocaleKeys.notifications_filter_comments,
        _Filter.follows => LocaleKeys.notifications_filter_follows,
      }
          .tr();

  /// "Today", "Yesterday", else the date.
  String _dayLabel(DateTime day) {
    if (day.isToday) return LocaleKeys.notifications_today.tr();
    if (day.isYesterday) return LocaleKeys.notifications_yesterday.tr();
    return '${day.year}/${day.month.toString().padLeft(2, '0')}/'
        '${day.day.toString().padLeft(2, '0')}';
  }

  /// Day headers (String) and rows (NotificationModel), newest first.
  List<Object> _entries(List<NotificationModel> items) {
    final out = <Object>[];
    DateTime? last;
    for (final n in items.where(_matches)) {
      final day = n.createdAt.toLocal();
      if (last == null || !last.isSameDay(day)) {
        out.add(_dayLabel(day));
        last = day;
      }
      out.add(n);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final hasUnread = ref.watch(unreadNotificationsProvider) > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: ArtoraBottomNav(
        currentIndex: null,
        onSelected: (index) => context.go(ArtoraBottomNav.tabPaths[index]),
        onCreate: ArtoraBottomNav.showCreateComingSoon,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Compact so the title stays aligned with the rows below.
                  IconButton(
                    tooltip: LocaleKeys.common_back.tr(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 36.r,
                      height: 36.r,
                    ),
                    icon: const Icon(AppIcons.back),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                  ),
                  AppSpacing.hGap(AppSpacing.sm),
                  Text(
                    LocaleKeys.notifications_title.tr(),
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _FilterRow(
              labels: [for (final f in _Filter.values) _filterLabel(f)],
              selected: _filter.index,
              onSelected: (i) => setState(() => _filter = _Filter.values[i]),
              onMarkAllRead: hasUnread ? notifier.markAllRead : null,
            ),
            AppSpacing.vGap(AppSpacing.sm),
            Expanded(
              child: switch (state) {
                RequestInitial() || RequestLoading() => const AppLoading(),
                RequestFailure(:final failure) => AppErrorWidget(
                    message: failure.message,
                    onRetry: notifier.refresh,
                  ),
                RequestSuccess(:final data) => _list(data, notifier),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<NotificationModel> data, NotificationsNotifier notifier) {
    final entries = _entries(data);
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: entries.isEmpty
          ? ListView(
              children: [
                AppEmptyState(
                  icon: AppIcons.notifications,
                  title: LocaleKeys.notifications_empty.tr(),
                  subtitle: LocaleKeys.notifications_empty_hint.tr(),
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                // Clear the floating bottom nav.
                bottom: MediaQuery.paddingOf(context).bottom + 110.r,
              ),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                if (entry is String) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      i == 0 ? AppSpacing.xs : AppSpacing.md,
                      AppSpacing.pagePadding,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      entry,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                // No divider above the first row of a day or after a header.
                final first = i == 0 || entries[i - 1] is String;
                return _NotificationRow(
                  item: entry as NotificationModel,
                  showDivider: !first,
                );
              },
            ),
    );
  }
}

// ── Filter row ─────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.onMarkAllRead,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) AppSpacing.hGap(AppSpacing.sm),
                    _Chip(
                      label: labels[i],
                      selected: i == selected,
                      onTap: () => onSelected(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AppSpacing.hGap(AppSpacing.sm),
          // The tune button opens the only action there is: mark all read.
          Builder(
            builder: (context) => _SquareButton(
              icon: AppIcons.tune,
              tooltip: LocaleKeys.notifications_mark_all_read.tr(),
              onTap: onMarkAllRead == null
                  ? null
                  : () async {
                      final box = context.findRenderObject()! as RenderBox;
                      final origin = box.localToGlobal(Offset.zero);
                      final picked = await showMenu<bool>(
                        context: context,
                        color: AppColors.elevated,
                        position: RelativeRect.fromLTRB(
                          origin.dx,
                          origin.dy + box.size.height,
                          origin.dx + box.size.width,
                          0,
                        ),
                        items: [
                          PopupMenuItem(
                            value: true,
                            child: Text(
                              LocaleKeys.notifications_mark_all_read.tr(),
                            ),
                          ),
                        ],
                      );
                      if (picked ?? false) onMarkAllRead!();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.md,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.background : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppBorders.md,
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36.r,
            height: 32.h,
            child: Icon(icon, size: 18.r, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ── Row ────────────────────────────────────────────────────

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item, required this.showDivider});

  final NotificationModel item;
  final bool showDivider;

  String get _action => switch (item.type) {
        NotificationType.like => LocaleKeys.notifications_liked,
        NotificationType.comment => LocaleKeys.notifications_commented,
        NotificationType.follow => LocaleKeys.notifications_followed,
      };

  /// "now", "2m ago", "1h ago", "3d ago", "2w ago", then the date.
  String _ago() {
    final created = item.createdAt.toLocal();
    final d = DateTime.now().difference(created);
    if (d.inMinutes < 1) return LocaleKeys.notifications_time_now.tr();
    String ago(String key, int n) => key.tr(namedArgs: {'count': '$n'});
    if (d.inHours < 1) {
      return ago(LocaleKeys.notifications_time_minutes, d.inMinutes);
    }
    if (d.inDays < 1) {
      return ago(LocaleKeys.notifications_time_hours, d.inHours);
    }
    if (d.inDays < 7) return ago(LocaleKeys.notifications_time_days, d.inDays);
    if (d.inDays < 30) {
      return ago(LocaleKeys.notifications_time_weeks, d.inDays ~/ 7);
    }
    return '${created.year}/${created.month.toString().padLeft(2, '0')}/'
        '${created.day.toString().padLeft(2, '0')}';
  }

  void _open(BuildContext context, WidgetRef ref) {
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).markRead(item.id);
    }
    final artworkId = item.artworkId;
    context.push(
      item.type == NotificationType.follow || artworkId == null
          ? AppRoutes.artistProfilePath(item.actorId)
          : AppRoutes.artworkDetailPath(artworkId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = context.textTheme;
    final unread = !item.isRead;
    final comment = item.commentText?.trim() ?? '';
    final isFollow = item.type == NotificationType.follow;

    return InkWell(
      onTap: () => _open(context, ref),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.ms,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: AppAvatar(
                    imageUrl: item.actorAvatarUrl,
                    initials: item.actorName,
                    radius: 26,
                  ),
                ),
                AppSpacing.hGap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: item.actorUsername.isEmpty
                                  ? item.actorName
                                  : item.actorUsername,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: _action.tr()),
                          ],
                        ),
                      ),
                      if (comment.isNotEmpty &&
                          item.type == NotificationType.comment) ...[
                        AppSpacing.vGap(AppSpacing.xs),
                        Text(
                          comment,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      AppSpacing.vGap(AppSpacing.xs),
                      Text(
                        _ago(),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGap(AppSpacing.sm),
                if (isFollow)
                  _FollowBackButton(userId: item.actorId)
                else
                  _Thumb(url: item.artworkThumbUrl),
              ],
            ),
          ),
          // Unread marker on the left edge, level with the avatar.
          if (unread)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 6.r,
                  height: 12.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(6.r),
                    ),
                  ),
                ),
              ),
            ),
          if (showDivider)
            Positioned(
              left: AppSpacing.pagePadding,
              right: AppSpacing.pagePadding,
              top: 0,
              child: const Divider(height: 1, color: AppColors.border),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final image = url;
    return Container(
      width: 64.r,
      height: 64.r,
      decoration: BoxDecoration(
        borderRadius: AppBorders.md,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: AppBorders.md,
        child: image == null || image.isEmpty
            ? const ColoredBox(
                color: AppColors.elevated,
                child: Icon(AppIcons.image, color: AppColors.textSecondary),
              )
            : CommonImage(imageUrl: image, fit: BoxFit.cover),
      ),
    );
  }
}

/// Follow Back until you follow them, then Following (tap to undo).
class _FollowBackButton extends StatelessWidget {
  const _FollowBackButton({required this.userId});

  final String userId;

  // They followed you, so the not-following state is always Follow Back.
  @override
  Widget build(BuildContext context) =>
      FollowButton(userId: userId, followsMe: true, width: 112.w);
}
