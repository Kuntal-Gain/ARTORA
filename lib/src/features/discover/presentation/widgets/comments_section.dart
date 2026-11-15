import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/state/comments_provider.dart';
import 'package:artora/src/imports/imports.dart';

/// Post-screen preview: "Comments (n)" + See All and the first few comments.
/// Everything else lives on the full comments screen.
class CommentsPreview extends ConsumerWidget {
  const CommentsPreview({
    super.key,
    required this.artworkId,
    required this.ownerId,
  });

  final String artworkId;
  final String ownerId;

  /// How many comments to show before "See All".
  static const _previewCount = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentsProvider(artworkId));
    final textTheme = context.textTheme;
    final me = AppConfig.supabase.auth.currentUser?.id;
    void open() => context.push(AppRoutes.artworkCommentsPath(artworkId));

    final (total, shown) = switch (state) {
      RequestSuccess(:final data) => (
          data.total,
          data.comments.take(_previewCount).toList(),
        ),
      _ => (0, const <CommentModel>[]),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Comments ($total)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            InkWell(
              onTap: open,
              child: Text(
                LocaleKeys.discover_see_all.tr(),
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vGap(AppSpacing.sm),
        if (shown.isNotEmpty)
          for (final comment in shown)
            CommentTile(
              comment: comment,
              canDelete: me == comment.userId || me == ownerId,
              onLike: () => ref
                  .read(commentsProvider(artworkId).notifier)
                  .toggleLike(comment.id),
              onReply: open,
              onDelete: () => ref
                  .read(commentsProvider(artworkId).notifier)
                  .delete(comment.id),
            )
        else
          InkWell(
            onTap: open,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                state is RequestSuccess
                    ? LocaleKeys.comments_empty.tr()
                    : '',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

/// One comment row: avatar, name · time, text, then like / Reply / ⋮.
/// Pass [onReply] as null for replies (they can't be replied to).
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.canDelete,
    required this.onLike,
    required this.onDelete,
    this.onReply,
  });

  final CommentModel comment;
  final bool canDelete;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback? onReply;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: Text(LocaleKeys.comments_delete_title.tr()),
        content: Text(
          (comment.isReply
                  ? LocaleKeys.comments_delete_reply_message
                  : LocaleKeys.comments_delete_comment_message)
              .tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocaleKeys.common_delete.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final author = comment.author;
    final created = comment.createdAt;
    final secondary =
        textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: author?.avatarUrl ?? '',
            initials: author?.displayName ?? '',
            radius: comment.isReply ? 16 : 22,
          ),
          AppSpacing.hGap(AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author?.username ?? LocaleKeys.comments_unknown.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (created != null) ...[
                      AppSpacing.hGap(AppSpacing.sm),
                      Text(shortTimeAgo(created), style: secondary),
                    ],
                  ],
                ),
                AppSpacing.vGap(AppSpacing.xs),
                Text(
                  comment.content,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
                AppSpacing.vGap(AppSpacing.xs),
                Row(
                  children: [
                    InkWell(
                      onTap: onLike,
                      borderRadius: AppBorders.sm,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLiked
                                  ? AppIcons.likeFilled
                                  : AppIcons.like,
                              size: 18.r,
                              color: comment.isLiked
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            AppSpacing.hGap(AppSpacing.xs),
                            Text(
                              formatCompact(comment.likesCount),
                              style: secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onReply != null) ...[
                      AppSpacing.hGap(AppSpacing.lg),
                      InkWell(
                        onTap: onReply,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            LocaleKeys.comments_reply.tr(),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    SizedBox.square(
                      dimension: 28.r,
                      child: PopupMenuButton<VoidCallback>(
                        padding: EdgeInsets.zero,
                        iconSize: 18.r,
                        icon: const Icon(
                          AppIcons.more,
                          color: AppColors.textSecondary,
                        ),
                        color: AppColors.elevated,
                        onSelected: (action) => action(),
                        // `_` so Delete's dialog uses the tile's context,
                        // which outlives the closed menu.
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: () =>
                                CopyService.instance.copy(comment.content),
                            child: Text(LocaleKeys.comments_copy_text.tr()),
                          ),
                          if (canDelete)
                            PopupMenuItem(
                              value: () => _confirmDelete(context),
                              child: Text(
                                LocaleKeys.common_delete.tr(),
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "now", "5m ago", "2h ago", "1d ago", "3w ago", then a date.
String shortTimeAgo(DateTime time) {
  final d = DateTime.now().difference(time.toLocal());
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  if (d.inDays < 30) return '${d.inDays ~/ 7}w ago';
  final local = time.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
