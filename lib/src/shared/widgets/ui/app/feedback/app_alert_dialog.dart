import '../../../../../imports/imports.dart';

/// Confirm / cancel dialog: round icon badge, centred title and message, and
/// an outlined Cancel next to a filled confirm button.
///
/// Looks the same on every platform. Set [isDestructive] for delete / sign-out
/// style actions (red badge and button); otherwise the primary colour is used.
///
/// Usage:
/// ```dart
/// final ok = await showAppAlertDialog(
///   context,
///   icon: AppIcons.delete,
///   title: 'Delete Artwork?',
///   message: 'This artwork will be permanently deleted.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// if (ok == true) { ... }
/// ```
/// For the common cases see [AppDialogPresets].
class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.confirmLabel = 'OK',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  final String title;
  final String? message;

  /// Shown in a round badge above the title; omit for no badge.
  final IconData? icon;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? AppColors.google : AppColors.primary;
    final textTheme = context.textTheme;

    return Dialog(
      backgroundColor: AppColors.elevated,
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.lg,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppBorders.dialog,
        side: BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 56.r,
                  height: 56.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.14),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, color: accent, size: 26.r),
                ),
                AppSpacing.vGap(AppSpacing.md),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                AppSpacing.vGap(AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              AppSpacing.vGap(AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: cancelLabel,
                      variant: ButtonVariant.outline,
                      textColor: AppColors.textPrimary,
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  AppSpacing.hGap(AppSpacing.ms),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      color: accent,
                      textColor: AppColors.white,
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).pop(true),
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

/// Presents [AppAlertDialog]; completes with `true` if confirmed, `false` if
/// cancelled and `null` if dismissed by tapping outside.
Future<bool?> showAppAlertDialog(
  BuildContext context, {
  required String title,
  String? message,
  IconData? icon,
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppAlertDialog(
      title: title,
      message: message,
      icon: icon,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
}
