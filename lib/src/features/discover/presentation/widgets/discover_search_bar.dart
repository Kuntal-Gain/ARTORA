import 'package:artora/src/imports/imports.dart';

/// Search pill on home and explore. It only looks like a field: tapping it
/// opens the search screen.
class DiscoverSearchBar extends StatelessWidget {
  const DiscoverSearchBar({
    super.key,
    required this.hint,
    required this.onTap,
    this.onFilter,
  });

  final String hint;
  final VoidCallback onTap;

  /// Shows the filter icon when set.
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: hint,
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.md,
          side: BorderSide(color: colors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48.h,
            child: Row(
              children: [
                AppSpacing.hGap(AppSpacing.md),
                Icon(
                  Icons.search_rounded,
                  size: 22.r,
                  color: colors.onSurfaceVariant,
                ),
                AppSpacing.hGap(AppSpacing.ms),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (onFilter != null)
                  IconButton(
                    onPressed: onFilter,
                    icon: Icon(Icons.tune_rounded, color: colors.onSurface),
                  )
                else
                  AppSpacing.hGap(AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
