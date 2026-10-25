import '../../../../imports/imports.dart';

/// Follow / Following toggle button.
///
/// Usage:
/// ```dart
/// AppFollowButton(isFollowing: artist.isFollowing, onPressed: _toggleFollow)
/// ```
class AppFollowButton extends StatelessWidget {
  const AppFollowButton({
    super.key,
    required this.isFollowing,
    this.onPressed,
    this.isLoading = false,
    this.height = ButtonSize.small,
  });

  final bool isFollowing;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonSize height;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: isFollowing ? 'Following' : 'Follow',
      variant: isFollowing ? ButtonVariant.outline : ButtonVariant.primary,
      height: height,
      isLoading: isLoading,
      onPressed: onPressed,
      prefixIcon: isFollowing
          ? Icon(Icons.check_rounded, size: 16.sp, color: context.colors.primary)
          : null,
    );
  }
}
