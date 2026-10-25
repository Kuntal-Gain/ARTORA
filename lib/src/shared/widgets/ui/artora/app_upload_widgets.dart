import '../../../../imports/imports.dart';

/// Labelled upload progress bar with percentage.
///
/// Usage: `AppUploadProgress(value: 0.72, label: 'Uploading artwork…')`
class AppUploadProgress extends StatelessWidget {
  const AppUploadProgress({
    super.key,
    required this.value,
    this.label = 'Uploading artwork…',
  });

  /// Progress from 0–1.
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppProgressBar(value: clamped),
        AppSpacing.vGap(AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: tt.bodySmall?.copyWith(color: cs.primary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Empty image slot (e.g. before an artwork is picked).
class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({
    super.key,
    this.onTap,
    this.icon = Icons.image_outlined,
    this.aspectRatio = 1,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Material(
        color: AppColors.imagePlaceholder,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.md,
          side: BorderSide(color: cs.outline),
        ),
        child: InkWell(
          borderRadius: AppBorders.md,
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 32.sp, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Failed-upload state with a retry action.
///
/// Usage: `AppUploadRetry(onRetry: _retryUpload)`
class AppUploadRetry extends StatelessWidget {
  const AppUploadRetry({
    super.key,
    required this.onRetry,
    this.message = 'Failed to upload',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 32.sp, color: cs.primary),
        AppSpacing.vGap(AppSpacing.sm),
        Text(
          message,
          style: context.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        AppSpacing.vGap(AppSpacing.md),
        AppButton(
          label: 'Retry',
          height: ButtonSize.small,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
