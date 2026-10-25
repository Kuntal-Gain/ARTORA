import '../../../../imports/imports.dart';

/// Compact profile header: avatar, name, bio, follow action and stats.
///
/// Usage:
/// ```dart
/// AppProfileHeader(
///   name: 'Luna Art',
///   handle: '@lunaart',
///   bio: 'Digital artist & concept artist',
///   isVerified: true,
///   artworks: 124,
///   followers: 12800,
///   following: 328,
///   isFollowing: false,
///   onFollow: _toggleFollow,
/// )
/// ```
class AppProfileHeader extends StatelessWidget {
  const AppProfileHeader({
    super.key,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.bio,
    this.isVerified = false,
    this.artworks = 0,
    this.followers = 0,
    this.following = 0,
    this.isFollowing,
    this.onFollow,
    this.onEdit,
  });

  final String name;
  final String handle;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final int artworks;
  final int followers;
  final int following;

  /// `null` hides the follow button.
  final bool? isFollowing;
  final VoidCallback? onFollow;

  /// When set, shows an "Edit Profile" button instead of follow.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(imageUrl: avatarUrl, initials: name, radius: 32),
              const Spacer(),
              if (onEdit != null)
                AppButton(
                  label: 'Edit Profile',
                  variant: ButtonVariant.outline,
                  height: ButtonSize.small,
                  onPressed: onEdit,
                )
              else if (isFollowing != null)
                AppFollowButton(isFollowing: isFollowing!, onPressed: onFollow),
            ],
          ),
          AppSpacing.vGap(AppSpacing.sm),
          AppArtistName(name: name, isVerified: isVerified),
          Text(handle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          if (bio != null) ...[
            AppSpacing.vGap(AppSpacing.xs),
            Text(bio!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
          AppSpacing.vGap(AppSpacing.md),
          Row(
            children: [
              _ProfileStat(value: artworks, label: 'Artworks'),
              _ProfileStat(value: followers, label: 'Followers'),
              _ProfileStat(value: following, label: 'Following'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            formatCompact(value),
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
