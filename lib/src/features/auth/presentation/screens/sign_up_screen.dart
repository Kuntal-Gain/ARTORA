import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:artora/src/imports/imports.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _acceptedTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _showTermsError = !_acceptedTerms);
    if (!valid || !_acceptedTerms) return;
    ref
        .read(signUpProvider.notifier)
        .submit((
          name: _name.text.trim(),
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        ));
  }

  AppFieldStatus _statusOf(bool valid) =>
      valid ? AppFieldStatus.success : AppFieldStatus.none;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpProvider);
    ref.listen(signUpProvider, (_, next) {
      switch (next) {
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestSuccess():
          showGlobalToast(message: LocaleKeys.auth_account_created.tr());
        case RequestInitial() || RequestLoading():
          break;
      }
    });

    final colors = context.colors;
    final textTheme = context.textTheme;
    final checks = AppValidators.checkPassword(_password.text);
    final linkStyle = textTheme.bodySmall?.copyWith(
      color: colors.primary,
      decoration: TextDecoration.underline,
      decorationColor: colors.primary,
    );

    return AuthScaffold(
      title: LocaleKeys.auth_create_your_account.tr(),
      subtitle: LocaleKeys.auth_sign_up_subtitle.tr(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthField(
                label: LocaleKeys.auth_display_name.tr(),
                hint: 'Alex Rivera',
                controller: _name,
                icon: const Icon(Icons.person_outline_rounded),
                validator: AppValidators.displayName,
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.formFieldGap),
              AuthField(
                label: LocaleKeys.auth_username.tr(),
                hint: 'alexrart',
                controller: _username,
                icon: const Icon(Icons.alternate_email_rounded),
                validator: AppValidators.username,
                status: _statusOf(AppValidators.isValidUsername(_username.text)),
                onChanged: (_) => setState(() {}),
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.formFieldGap),
              AuthField(
                label: LocaleKeys.auth_email.tr(),
                hint: 'alex@example.com',
                controller: _email,
                icon: const Icon(Icons.mail_outline_rounded),
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
                status: _statusOf(AppValidators.isValidEmail(_email.text)),
                onChanged: (_) => setState(() {}),
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.formFieldGap),
              AuthField(
                label: LocaleKeys.auth_password.tr(),
                controller: _password,
                icon: const Icon(Icons.lock_outline_rounded),
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: AppValidators.newPassword,
                onChanged: (_) => setState(() {}),
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.ms),
              _PasswordRule(
                label: LocaleKeys.auth_rule_min_length.tr(),
                met: checks.minLength,
              ),
              _PasswordRule(
                label: LocaleKeys.auth_rule_number.tr(),
                met: checks.hasNumber,
              ),
              _PasswordRule(
                label: LocaleKeys.auth_rule_letter.tr(),
                met: checks.hasLetter,
              ),
              AppSpacing.vGap(AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCheckbox(
                    value: _acceptedTerms,
                    onChanged: state.isLoading
                        ? null
                        : (v) => setState(() {
                            _acceptedTerms = v ?? false;
                            _showTermsError = false;
                          }),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.ms),
                      child: Text.rich(
                        TextSpan(
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: LocaleKeys.auth_agree_prefix.tr()),
                            TextSpan(
                              text: LocaleKeys.auth_terms_of_service.tr(),
                              style: linkStyle,
                            ),
                            TextSpan(text: LocaleKeys.auth_agree_and.tr()),
                            TextSpan(
                              text: LocaleKeys.auth_privacy_policy.tr(),
                              style: linkStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showTermsError)
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    LocaleKeys.auth_terms_required.tr(),
                    style: textTheme.bodySmall?.copyWith(color: colors.error),
                  ),
                ),
              AppSpacing.vGap(AppSpacing.lg),
              AppButton(
                label: LocaleKeys.auth_create_account_button.tr(),
                isFullWidth: true,
                height: ButtonSize.small,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              AppSpacing.vGap(AppSpacing.md),
              AuthSwitchPrompt(
                prompt: LocaleKeys.auth_already_have_account.tr(),
                action: LocaleKeys.auth_sign_in.tr(),
                onPressed: () => context.pushReplacement(AppRoutes.login),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One live requirement row; turns green once satisfied.
class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = met ? context.appColors.success : colors.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18.r,
            color: color,
          ),
          AppSpacing.hGap(AppSpacing.sm),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: met ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
