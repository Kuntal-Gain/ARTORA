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

/// Card with the image being uploaded and an [AppUploadProgress] bar.
class AppUploadCard extends StatelessWidget {
  const AppUploadCard({
    super.key,
    required this.value,
    required this.label,
    this.image,
  });

  final double value;
  final String label;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      width: 260.r,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppBorders.lg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: AppBorders.md,
              child: Image(
                image: image!,
                width: 112.r,
                height: 112.r,
                fit: BoxFit.cover,
              ),
            ),
            AppSpacing.vGap(AppSpacing.lg),
          ],
          AppUploadProgress(value: value, label: label),
        ],
      ),
    );
  }
}

/// Covers [child] with a dimmed barrier and an [AppUploadCard] while
/// [progress] is non-null.
class AppUploadOverlay extends StatelessWidget {
  const AppUploadOverlay({
    super.key,
    required this.progress,
    required this.label,
    required this.child,
    this.image,
  });

  final ValueListenable<double?> progress;
  final String label;
  final ImageProvider? image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (context, value, _) {
            if (value == null) return const SizedBox.shrink();
            return Positioned.fill(
              child: ColoredBox(
                color: AppColors.background.withValues(alpha: 0.6),
                child: Center(
                  child: AppUploadCard(value: value, label: label, image: image),
                ),
              ),
            );
          },
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
    this.icon = AppIcons.image,
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
        Icon(AppIcons.cloudUpload, size: 32.sp, color: cs.primary),
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
