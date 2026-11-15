import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/theme/app_fonts.dart';

/// First onboarding page: hero artwork, headline, and primary actions.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    final titleStyle = textTheme.displaySmall?.copyWith(
      fontSize: 34.sp,
      fontWeight: FontWeight.w700,
      height: 1.15,
      fontFamily: AppFonts.playfairDisplay,
      color: colors.onSurface,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom inset shrinks the artwork box so the image sits higher.
          Padding(
            padding: EdgeInsets.only(bottom: 140.h),
            child: Image.asset(
              AppAssets.welcomeBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Fades the artwork into the background so the copy stays legible.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.38, 0.62, 1.0],
                colors: [
                  AppColors.transparent,
                  AppColors.transparent,
                  Color(0xC7101014),
                  Color(0xF5101014),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppSpacing.insetPage.copyWith(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(LocaleKeys.welcome_title_line_1.tr(), style: titleStyle),
                  Text(
                    LocaleKeys.welcome_title_highlight.tr(),
                    style: titleStyle?.copyWith(
                      color: colors.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  AppSpacing.vGap(AppSpacing.md),
                  Text(
                    LocaleKeys.welcome_subtitle.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.82),
                      height: 1.55,
                    ),
                  ),
                  AppSpacing.vGap(AppSpacing.lg),
                  AppButton(
                    label: LocaleKeys.welcome_get_started.tr(),
                    height: ButtonSize.small,
                    isFullWidth: true,
                    onPressed: () => context.push(AppRoutes.signup),
                
                    suffixIcon: Icon(
                      AppIcons.forward,
                      size: 20.r,
                      color: colors.onPrimary,
                    ),
                  ),
                  AppSpacing.vGap(AppSpacing.ms),
                  AppButton(
                    label: LocaleKeys.welcome_sign_in.tr(),
                    variant: ButtonVariant.outline,
                    textColor: colors.onSurface,
                    height: ButtonSize.small,
                    isFullWidth: true,
                    onPressed: () => context.push(AppRoutes.login),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
