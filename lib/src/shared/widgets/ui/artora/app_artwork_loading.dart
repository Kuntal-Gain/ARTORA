import '../../../../imports/imports.dart';

/// Image placeholder: a dim gradient with an image icon and "Loading
/// artwork...". Fills whatever space it is given, so use it as the loading
/// state of an artwork image:
///
/// ```dart
/// CommonImage(imageUrl: url, placeholder: const AppArtworkLoading())
/// ```
class AppArtworkLoading extends StatelessWidget {
  const AppArtworkLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.elevated, AppColors.surface],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.image, size: 40.r, color: AppColors.textPrimary),
            AppSpacing.vGap(AppSpacing.sm),
            Text(
              LocaleKeys.artwork_loading.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
