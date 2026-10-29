import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:artora/src/imports/imports.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(loginProvider.notifier)
        .submit((email: _email.text.trim(), password: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    ref.listen(loginProvider, (_, next) {
      switch (next) {
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestSuccess(:final data):
          showGlobalToast(message: LocaleKeys.auth_signed_in.tr());
          context.go(data ? AppRoutes.profileSetup : AppRoutes.home);
        case RequestInitial() || RequestLoading():
          break;
      }
    });

    final colors = context.colors;

    return AuthScaffold(
      title: LocaleKeys.auth_welcome_back.tr(),
      subtitle: LocaleKeys.auth_sign_in_subtitle.tr(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthField(
                label: LocaleKeys.auth_email.tr(),
                hint: 'artist@example.com',
                controller: _email,
                icon: const Icon(Icons.mail_outline_rounded),
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.groupGap),
              AuthField(
                label: LocaleKeys.auth_password.tr(),
                controller: _password,
                icon: const Icon(Icons.lock_outline_rounded),
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: AppValidators.passwordRequired,
                onSubmitted: (_) => _submit(),
                enabled: !state.isLoading,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: Text(LocaleKeys.auth_forgot_password_link.tr()),
                ),
              ),
              AppSpacing.vGap(AppSpacing.lg),
              AppButton(
                label: LocaleKeys.auth_sign_in.tr(),
                isFullWidth: true,
                height: ButtonSize.small,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              AppSpacing.vGap(AppSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      LocaleKeys.auth_or.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              AppSpacing.vGap(AppSpacing.md),
              AuthSwitchPrompt(
                prompt: LocaleKeys.auth_dont_have_account.tr(),
                action: LocaleKeys.auth_sign_up.tr(),
                onPressed: () => context.pushReplacement(AppRoutes.signup),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
