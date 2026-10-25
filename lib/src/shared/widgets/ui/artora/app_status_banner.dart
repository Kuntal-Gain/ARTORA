import '../../../../imports/imports.dart';

enum AppStatusType { success, error, warning, info }

/// Inline status card: tinted container, icon badge, title and message.
///
/// Usage:
/// ```dart
/// AppStatusBanner(
///   type: AppStatusType.success,
///   title: 'Reset link sent!',
///   message: "We've sent a password reset link to you@mail.com.",
/// )
/// ```
class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.type,
    required this.title,
    this.message,
  });

  final AppStatusType type;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final ac = context.appColors;
    final tt = context.textTheme;

    final (accent, container, icon) = switch (type) {
      AppStatusType.success => (
          ac.success,
          ac.successContainer ?? cs.secondaryContainer,
          Icons.check_rounded,
        ),
      AppStatusType.error => (
          cs.error,
          cs.errorContainer,
          Icons.priority_high_rounded,
        ),
      AppStatusType.warning => (
          ac.warning,
          ac.warningContainer ?? cs.secondaryContainer,
          Icons.warning_amber_rounded,
        ),
      AppStatusType.info => (
          ac.info,
          ac.infoContainer ?? cs.secondaryContainer,
          Icons.info_outline_rounded,
        ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: container.withValues(alpha: 0.5),
          borderRadius: AppBorders.md,
          border: Border.all(color: accent.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14.r,
              backgroundColor: accent,
              child: Icon(icon, size: 16.sp, color: cs.surface),
            ),
            AppSpacing.hGap(AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message != null) ...[
                    AppSpacing.vGap(AppSpacing.xs),
                    Text(
                      message!,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
