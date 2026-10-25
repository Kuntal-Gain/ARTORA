import '../../../../imports/imports.dart';

/// Screen title + subtitle block used at the top of auth / onboarding forms.
///
/// Usage: `AppAuthHeader(title: 'Welcome Back', subtitle: 'Sign in to continue')`
class AppAuthHeader extends StatelessWidget {
  const AppAuthHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        if (subtitle != null) ...[
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            subtitle!,
            style: tt.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Divider with a centred label (e.g. "or").
class AppOrDivider extends StatelessWidget {
  const AppOrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

/// "Don't have an account? Sign Up" footer prompt.
///
/// Usage:
/// ```dart
/// AppAuthPrompt(
///   prompt: "Don't have an account?",
///   actionLabel: 'Sign Up',
///   onPressed: () => context.go(AppRoutes.signup),
/// )
/// ```
class AppAuthPrompt extends StatelessWidget {
  const AppAuthPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: context.textTheme.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        AppTextButton(label: actionLabel, onPressed: onPressed),
      ],
    );
  }
}

/// Large circular icon used as the focal point of simple screens
/// (forgot password, email sent…).
class AppHeroIcon extends StatelessWidget {
  const AppHeroIcon({super.key, required this.icon, this.size = 80});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary.withValues(alpha: 0.12),
        border: Border.all(color: cs.primary, width: 1.5),
      ),
      child: Icon(icon, size: (size * 0.45).sp, color: cs.primary),
    );
  }
}

/// Brand wordmark with optional tagline, used on splash / welcome screens.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    required this.name,
    this.tagline,
    this.iconSize = 56,
  });

  final String name;
  final String? tagline;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.change_history_rounded, size: iconSize.sp, color: cs.primary),
        AppSpacing.vGap(AppSpacing.sm),
        Text(
          name.toUpperCase(),
          style: tt.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 8,
          ),
        ),
        if (tagline != null) ...[
          AppSpacing.vGap(AppSpacing.md),
          Text(
            tagline!.toUpperCase(),
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
              letterSpacing: 3,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Circular profile-photo picker with a camera badge and caption.
///
/// Usage: `AppAvatarPicker(imageUrl: url, onTap: _pickImage)`
class AppAvatarPicker extends StatelessWidget {
  const AppAvatarPicker({
    super.key,
    this.imageUrl,
    this.onTap,
    this.radius = 40,
    this.caption = 'Tap to upload a photo',
  });

  final String? imageUrl;
  final VoidCallback? onTap;
  final double radius;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Upload profile photo',
          child: InkResponse(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary, width: 2),
                  ),
                  child: AppAvatar(
                    imageUrl: imageUrl,
                    initials: '+',
                    radius: radius,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 14.r,
                    backgroundColor: cs.primary,
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 16.sp,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (caption != null) ...[
          AppSpacing.vGap(AppSpacing.sm),
          Text(
            caption!,
            style: context.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
