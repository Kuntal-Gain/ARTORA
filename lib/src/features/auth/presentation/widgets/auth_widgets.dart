import 'package:artora/src/imports/imports.dart';

/// Shared page frame: back arrow, heading, subtitle and a scrollable body.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed top bar: stays in place while the content scrolls.
                Padding(
                  padding: AppSpacing.insetPage.copyWith(top: AppSpacing.sm),
                  child: Tooltip(
                    message: MaterialLocalizations.of(context).backButtonTooltip,
                    child: InkResponse(
                      radius: 24,
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.onboarding),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: AppSpacing.insetPage.copyWith(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          AppSpacing.vGap(AppSpacing.sm),
                          Text.rich(
                            _brandHighlighted(subtitle!, colors.primary, context),
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                        AppSpacing.vGap(AppSpacing.xl),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const String _brandName = 'ARTORA';

/// Colors every occurrence of the brand name inside [text].
TextSpan _brandHighlighted(String text, Color color , BuildContext context) {
  final parts = text.split(_brandName);
  return TextSpan(
    children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0)
          TextSpan(
            text: _brandName,
            style: context.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFamily: AppFonts.playfairDisplay,
              fontStyle: FontStyle.normal,
            ),
          ),
        TextSpan(text: parts[i]),
      ],
    ],
  );
}

/// Field with a visible label above it (never placeholder-only).
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.status = AppFieldStatus.none,
    this.obscure = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final Widget icon;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final AppFieldStatus status;

  /// Renders a password field (with visibility toggle) instead of plain text.
  final bool obscure;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
          ),
        ),
        AppSpacing.vGap(AppSpacing.sm),
        if (obscure)
          AppPasswordField(
            label: null,
            hint: hint,
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            textInputAction: textInputAction,
            enabled: enabled,
            prefixIcon: icon,
          )
        else
          AppTextField(
            hint: hint,
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            enabled: enabled,
            status: status,
            prefixIcon: icon,
          ),
      ],
    );
  }
}

enum AuthNoticeType { success, error }

/// Tinted result card shown under a form (e.g. reset link sent / failed).
class AuthNoticeCard extends StatelessWidget {
  const AuthNoticeCard({
    super.key,
    required this.type,
    required this.title,
    required this.message,
  });

  final AuthNoticeType type;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == AuthNoticeType.success;
    final accent = isSuccess ? context.appColors.success : context.colors.error;
    final tt = context.textTheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.insetCard,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: AppBorders.card,
          border: Border.all(color: accent.withValues(alpha: 0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.priority_high_rounded,
                size: 18.r,
                color: AppColors.background,
              ),
            ),
            AppSpacing.hGap(AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.vGap(AppSpacing.xs),
                  Text(
                    message,
                    style: tt.bodySmall?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Already have an account? Sign In" style footer row.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt.trim(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
