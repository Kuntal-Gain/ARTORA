import 'package:artora/src/imports/imports.dart';

/// Equal-width text tabs with a rounded purple bar under the selected one and
/// a hairline under the whole row.
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.dense = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Smaller text and padding, for tabs nested inside a section.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = dense
        ? context.textTheme.titleSmall
        : context.textTheme.titleMedium;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selectedIndex,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: dense ? AppSpacing.sm : AppSpacing.ms,
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: baseStyle?.copyWith(
                            color: i == selectedIndex
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            fontWeight: i == selectedIndex
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: AppDurations.fast,
                        curve: AppCurves.standard,
                        height: 3.r,
                        margin: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: i == selectedIndex
                              ? colors.primary
                              : AppColors.transparent,
                          borderRadius: AppBorders.full,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
