import 'package:artora/src/imports/imports.dart';

/// Two-column masonry: each item goes into whichever column is shorter so far.
class MasonryGrid<T> extends StatelessWidget {
  const MasonryGrid({
    super.key,
    required this.items,
    required this.aspectRatioOf,
    required this.itemBuilder,
    this.footerExtent = 0.4,
  });

  final List<T> items;
  final double Function(T item) aspectRatioOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Rough height of the area under each image, as a fraction of the column
  /// width. Only affects how items are balanced between columns.
  final double footerExtent;

  @override
  Widget build(BuildContext context) {
    final left = <T>[];
    final right = <T>[];
    var leftHeight = 0.0;
    var rightHeight = 0.0;
    for (final item in items) {
      final height = 1 / aspectRatioOf(item) + footerExtent;
      if (leftHeight <= rightHeight) {
        left.add(item);
        leftHeight += height;
      } else {
        right.add(item);
        rightHeight += height;
      }
    }

    Widget column(List<T> entries) => Column(
      children: [
        for (final (index, item) in entries.indexed) ...[
          if (index > 0) AppSpacing.vGap(AppSpacing.ms),
          itemBuilder(context, item),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(left)),
        AppSpacing.hGap(AppSpacing.ms),
        Expanded(child: column(right)),
      ],
    );
  }
}

/// Loading placeholder shaped like the masonry feed.
class MasonrySkeleton extends StatelessWidget {
  const MasonrySkeleton({super.key});

  static const List<double> _leftHeights = [230, 170, 210];
  static const List<double> _rightHeights = [180, 240, 160];

  @override
  Widget build(BuildContext context) {
    Widget column(List<double> heights) => Column(
      children: [
        for (final (index, height) in heights.indexed) ...[
          if (index > 0) AppSpacing.vGap(AppSpacing.ms),
          Container(
            height: height.h,
            decoration: const BoxDecoration(
              color: AppColors.shimmer,
              borderRadius: AppBorders.card,
            ),
          ),
        ],
      ],
    );

    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(_leftHeights)),
          AppSpacing.hGap(AppSpacing.ms),
          Expanded(child: column(_rightHeights)),
        ],
      ),
    );
  }
}
