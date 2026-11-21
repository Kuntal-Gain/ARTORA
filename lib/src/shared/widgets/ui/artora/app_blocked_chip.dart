import '../../../../imports/imports.dart';

/// Small "Blocked" label shown beside the Unblock button.
class AppBlockedChip extends StatelessWidget {
  const AppBlockedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final error = context.colors.error;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.12),
        borderRadius: AppBorders.full,
        border: Border.all(color: error.withValues(alpha: 0.4)),
      ),
      child: Text(
        LocaleKeys.block_blocked_chip.tr(),
        maxLines: 1,
        style: context.textTheme.labelSmall?.copyWith(
          color: error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
