import '../../../../imports/imports.dart';

/// Feed loading placeholder: a column of artwork-card skeletons.
class AppFeedSkeleton extends StatelessWidget {
  const AppFeedSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: AppSpacing.insetScreen,
        itemCount: itemCount,
        separatorBuilder: (_, __) => AppSpacing.vGap(AppSpacing.md),
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone.square(size: 220.h, borderRadius: AppBorders.card),
            AppSpacing.vGap(AppSpacing.sm),
            Row(
              children: [
                Bone.circle(size: 28.r),
                AppSpacing.hGap(AppSpacing.sm),
                const Expanded(child: Bone.text(words: 2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile loading placeholder.
class AppProfileSkeleton extends StatelessWidget {
  const AppProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Padding(
        padding: AppSpacing.insetScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone.circle(size: 64.r),
            AppSpacing.vGap(AppSpacing.md),
            const Bone.text(words: 2),
            AppSpacing.vGap(AppSpacing.xs),
            const Bone.text(words: 4),
            AppSpacing.vGap(AppSpacing.lg),
            Bone.square(size: 120.h, borderRadius: AppBorders.card),
          ],
        ),
      ),
    );
  }
}

/// Artwork detail loading placeholder.
class AppDetailSkeleton extends StatelessWidget {
  const AppDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone.square(size: 300.h, borderRadius: BorderRadius.zero),
          Padding(
            padding: AppSpacing.insetScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Bone.text(words: 3),
                AppSpacing.vGap(AppSpacing.sm),
                const Bone.text(words: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
