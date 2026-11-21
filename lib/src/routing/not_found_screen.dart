import 'dart:math' as math;

import 'package:artora/src/imports/imports.dart';

/// Shown by the router for any location that doesn't exist: an app bar, the
/// 404 illustration centred with a short message, and the way back home pinned
/// to the bottom.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        // Back only when there is somewhere to go back to (a bad deep link
        // has no previous page).
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                tooltip: LocaleKeys.common_back.tr(),
                icon: const Icon(AppIcons.back),
                onPressed: context.pop,
              )
            : null,
        title: Text(
          LocaleKeys.not_found_title.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The SVG has no width / height of its own, so give it an
                      // explicit square (it is drawn from a 500x500 viewBox).
                      SvgPicture.asset(
                        AppAssets.notFound,
                        width: math.min(
                          MediaQuery.sizeOf(context).width -
                              AppSpacing.pagePadding * 2,
                          360.w,
                        ),
                        fit: BoxFit.contain,
                        semanticsLabel: LocaleKeys.not_found_title.tr(),
                        // Show why instead of a blank space if it can't load
                        // (e.g. a new asset needs a full rebuild, not a reload).
                        errorBuilder: (context, error, stack) {
                          AppLogger.error(
                            'Could not load the 404 illustration',
                            error: error,
                            stackTrace: stack,
                          );
                          return Icon(
                            AppIcons.brokenImage,
                            size: 64.r,
                            color: context.colors.onSurfaceVariant,
                          );
                        },
                      ),
                      AppSpacing.vGap(AppSpacing.lg),
                      Text(
                        LocaleKeys.not_found_message.tr(),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              // Lifted well off the bottom edge.
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                48.h,
              ),
              child: AppButton(
                label: LocaleKeys.not_found_go_home.tr(),
                isFullWidth: true,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
