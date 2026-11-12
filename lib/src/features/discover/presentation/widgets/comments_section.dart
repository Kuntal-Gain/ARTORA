import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/state/comments_provider.dart';
import 'package:artora/src/imports/imports.dart';

/// Post-screen preview: "Comments (n)" + See All and the first comment.
/// Everything else lives on the full comments screen.
class CommentsPreview extends ConsumerWidget {
  const CommentsPreview({
    super.key,
    required this.artworkId,
    required this.ownerId,
  });

  final String artworkId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentsProvider(artworkId));
    final textTheme = context.textTheme;
    final me = AppConfig.supabase.auth.currentUser?.id;
    void open() => context.push(AppRoutes.artworkCommentsPath(artworkId));

    final (total, first) = switch (state) {
      RequestSuccess(:final data) => (data.total, data.comments.firstOrNull),
      _ => (0, null),
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
        if (first != null)
          CommentTile(
            comment: first,
            canDelete: me == first.userId || me == ownerId,
            onLike: () => ref
                .read(commentsProvider(artworkId).notifier)
                .toggleLike(first.id),
            onReply: open,
            onDelete: () => ref
                .read(commentsProvider(artworkId).notifier)
                .delete(first.id),
          )
        else
          InkWell(
            onTap: open,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                state is RequestSuccess
                    ? 'No comments yet. Be the first to share your thoughts!'
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
        title: const Text('Delete comment?'),
        content: Text(
          comment.isReply
              ? 'This reply will be removed.'
              : 'This comment and its replies will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
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
                        author?.username ?? 'Unknown',
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
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
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
                            'Reply',
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
                          Icons.more_vert_rounded,
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
                            child: const Text('Copy text'),
                          ),
                          if (canDelete)
                            PopupMenuItem(
                              value: () => _confirmDelete(context),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.error),
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
