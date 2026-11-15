import 'package:artora/src/features/discover/model/comment_model.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/comments_section.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/features/discover/state/comments_provider.dart';
import 'package:artora/src/imports/imports.dart';

/// Full comments page: artwork header, count + sort, threads, composer.
class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.artworkId});

  final String artworkId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  CommentModel? _replyingTo;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  CommentsNotifier get _notifier =>
      ref.read(commentsProvider(widget.artworkId).notifier);

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await _notifier.post(text, parentId: _replyingTo?.id);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _controller.clear();
        _replyingTo = null;
      }
    });
  }

  void _reply(CommentModel comment) {
    setState(() => _replyingTo = comment);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.artworkId;
    final state = ref.watch(commentsProvider(id));
    final art = switch (ref.watch(artworkDetailProvider(id))) {
      RequestSuccess(:final data) => data,
      _ => null,
    };
    final myAvatar = switch (ref.watch(currentArtistProvider)) {
      RequestSuccess(:final data) => data,
      _ => null,
    };
    final me = AppConfig.supabase.auth.currentUser?.id;
    final ownerId = art?.userId;
    final textTheme = context.textTheme;

    bool canDelete(CommentModel c) => me == c.userId || me == ownerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          LocaleKeys.comments_title.tr(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _notifier.refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.xs,
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                ),
                children: [
                  if (art != null) ...[
                    _ArtworkHeader(
                      imageUrl: art.images.firstOrNull?.thumbnailUrl ??
                          art.images.firstOrNull?.url ??
                          '',
                      title: art.title,
                      username: art.artist?.username,
                    ),
                    AppSpacing.vGap(AppSpacing.md),
                  ],
                  _CountRow(
                    total: switch (state) {
                      RequestSuccess(:final data) => data.total,
                      _ => 0,
                    },
                    newestFirst: switch (state) {
                      RequestSuccess(:final data) => data.newestFirst,
                      _ => true,
                    },
                    onSort: _notifier.setNewestFirst,
                  ),
                  AppSpacing.vGap(AppSpacing.xs),
                  ...switch (state) {
                    RequestInitial() || RequestLoading() => [
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xl),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    RequestFailure(:final failure) => [
                        AppErrorWidget(
                          message: failure.message,
                          onRetry: _notifier.refresh,
                        ),
                      ],
                    RequestSuccess(:final data) when data.comments.isEmpty => [
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xl),
                          child: Text(
                            LocaleKeys.comments_empty.tr(),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    RequestSuccess(:final data) => [
                        for (final comment in data.comments) ...[
                          CommentTile(
                            comment: comment,
                            canDelete: canDelete(comment),
                            onLike: () => _notifier.toggleLike(comment.id),
                            onReply: () => _reply(comment),
                            onDelete: () => _notifier.delete(comment.id),
                          ),
                          if (comment.repliesCount > 0 ||
                              data.replies.containsKey(comment.id))
                            Padding(
                              padding: EdgeInsets.only(left: 56.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final reply in data.replies[comment.id] ??
                                      const <CommentModel>[])
                                    CommentTile(
                                      comment: reply,
                                      canDelete: canDelete(reply),
                                      onLike: () =>
                                          _notifier.toggleLike(reply.id),
                                      onDelete: () =>
                                          _notifier.delete(reply.id),
                                    ),
                                  _RepliesToggle(
                                    expanded:
                                        data.replies.containsKey(comment.id),
                                    count: comment.repliesCount,
                                    onTap: () =>
                                        _notifier.toggleReplies(comment.id),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                  },
                ],
              ),
            ),
          ),
          _Composer(
            controller: _controller,
            focusNode: _focus,
            sending: _sending,
            avatarUrl: myAvatar?.avatarUrl,
            avatarInitials: myAvatar?.displayName,
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ArtworkHeader extends StatelessWidget {
  const _ArtworkHeader({
    required this.imageUrl,
    required this.title,
    required this.username,
  });

  final String imageUrl;
  final String title;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppBorders.md,
            child: SizedBox.square(
              dimension: 64.r,
              child: CommonImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          ),
          AppSpacing.hGap(AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (username != null && username!.isNotEmpty) ...[
                  AppSpacing.vGap(AppSpacing.xs),
                  Text(
                    'by $username',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.total,
    required this.newestFirst,
    required this.onSort,
  });

  final int total;
  final bool newestFirst;
  final ValueChanged<bool> onSort;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            LocaleKeys.comments_count.tr(
              namedArgs: {'count': formatCompact(total)},
            ),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        PopupMenuButton<bool>(
          color: AppColors.elevated,
          onSelected: onSort,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: true,
              child: Text(LocaleKeys.comments_newest.tr()),
            ),
            PopupMenuItem(
              value: false,
              child: Text(LocaleKeys.comments_oldest.tr()),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (newestFirst
                        ? LocaleKeys.comments_newest
                        : LocaleKeys.comments_oldest)
                    .tr(),
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              Icon(
                AppIcons.chevronDown,
                size: 18.r,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepliesToggle extends StatelessWidget {
  const _RepliesToggle({
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24.w,
                height: 1,
                color: AppColors.divider,
              ),
              AppSpacing.hGap(AppSpacing.sm),
              Text(
                expanded
                    ? LocaleKeys.comments_hide_replies.tr()
                    : count == 1
                        ? LocaleKeys.comments_view_reply.tr()
                        : LocaleKeys.comments_view_replies.tr(
                            namedArgs: {'count': '$count'},
                          ),
                style: context.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.avatarUrl,
    required this.avatarInitials,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final String? avatarUrl;
  final String? avatarInitials;
  final CommentModel? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final target = replyingTo;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (target != null)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to @${target.author?.username ?? 'comment'}',
                          style: textTheme.labelMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      InkWell(
                        onTap: onCancelReply,
                        child: Icon(
                          AppIcons.close,
                          size: 18.r,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  AppAvatar(
                    imageUrl: avatarUrl ?? '',
                    initials: avatarInitials ?? '',
                    radius: 20,
                  ),
                  AppSpacing.hGap(AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: (target == null
                                ? LocaleKeys.comments_add_comment
                                : LocaleKeys.comments_write_reply)
                            .tr(),
                        hintStyle: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.ms,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: AppBorders.full,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: AppBorders.full,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: AppBorders.full,
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  AppSpacing.hGap(AppSpacing.sm),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: sending ? null : onSend,
                      child: SizedBox.square(
                        dimension: 44.r,
                        child: Center(
                          child: sending
                              ? SizedBox.square(
                                  dimension: 18.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Icon(
                                  AppIcons.send,
                                  size: 20.r,
                                  color: AppColors.white,
                                  semanticLabel: LocaleKeys.comments_send.tr(),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
