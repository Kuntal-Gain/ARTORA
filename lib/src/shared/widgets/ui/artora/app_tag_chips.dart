import '../../../../imports/imports.dart';

/// Outlined `#tag` pill.
///
/// Usage: `AppTagChip(label: 'Fantasy', onTap: () => search('Fantasy'))`
class AppTagChip extends StatelessWidget {
  const AppTagChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return InkWell(
      borderRadius: AppBorders.full,
      onTap: onTap,
      child: Container(
        padding: AppSpacing.insetChip,
        decoration: BoxDecoration(
          borderRadius: AppBorders.full,
          border: Border.all(color: cs.outline),
        ),
        child: Text(
          '# $label',
          style: context.textTheme.labelMedium?.copyWith(color: cs.primary),
        ),
      ),
    );
  }
}

/// Wrapping list of [AppTagChip]s.
class AppTagList extends StatelessWidget {
  const AppTagList({super.key, required this.tags, this.onTap});

  final List<String> tags;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final tag in tags)
          AppTagChip(label: tag, onTap: onTap == null ? null : () => onTap!(tag)),
      ],
    );
  }
}

/// Horizontally scrolling single-select category chips.
///
/// Usage:
/// ```dart
/// AppCategoryChips(
///   categories: const ['All', 'Digital Painting', 'Anime'],
///   selectedIndex: index,
///   onSelected: (i) => setState(() => index = i),
/// )
/// ```
class AppCategoryChips extends StatelessWidget {
  const AppCategoryChips({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.insetPage,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) AppSpacing.hGap(AppSpacing.sm),
            AppChip(
              label: categories[i],
              selected: i == selectedIndex,
              onSelected: (_) => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Filters" chip with an active-filter count badge.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    this.label = 'Filters',
    this.count = 0,
    this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return InkWell(
      borderRadius: AppBorders.md,
      onTap: onTap,
      child: Container(
        padding: AppSpacing.insetField,
        decoration: BoxDecoration(
          borderRadius: AppBorders.md,
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 18.sp, color: cs.onSurface),
            AppSpacing.hGap(AppSpacing.sm),
            Text(label, style: context.textTheme.labelLarge),
            if (count > 0) ...[
              AppSpacing.hGap(AppSpacing.sm),
              AppBadge(
                label: '$count',
                color: cs.primary,
                textColor: cs.onPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
