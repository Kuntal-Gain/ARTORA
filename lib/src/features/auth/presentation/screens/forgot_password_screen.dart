import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:artora/src/imports/imports.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// Address the last request was sent to, shown in the success message.
  String _sentTo = '';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    _sentTo = _email.text.trim();
    ref.read(forgotPasswordProvider.notifier).submit(_sentTo);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final colors = context.colors;

    return AuthScaffold(
      title: LocaleKeys.auth_forgot_password_question.tr(),
      subtitle: LocaleKeys.auth_forgot_description.tr(),
      children: [
        Center(
          child: Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.12),
              border: Border.all(color: colors.primary, width: 1.5),
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 30.r,
              color: colors.primary,
            ),
          ),
        ),
        AppSpacing.vGap(AppSpacing.xl),
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
                textInputAction: TextInputAction.done,
                validator: AppValidators.email,
                onSubmitted: (_) => _submit(),
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.lg),
              AppButton(
                label: LocaleKeys.auth_send_reset_link.tr(),
                isFullWidth: true,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        AppSpacing.vGap(AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppDurations.normal,
          child: switch (state) {
            RequestSuccess() => AuthNoticeCard(
              key: const ValueKey('success'),
              type: AuthNoticeType.success,
              title: LocaleKeys.auth_reset_sent_title.tr(),
              message: LocaleKeys.auth_reset_sent_body.tr(
                namedArgs: {'email': _sentTo},
              ),
            ),
            RequestFailure(:final failure) => AuthNoticeCard(
              key: const ValueKey('error'),
              type: AuthNoticeType.error,
              title: LocaleKeys.auth_reset_failed_title.tr(),
              message: failure.message,
            ),
            RequestInitial() ||
            RequestLoading() => const SizedBox.shrink(key: ValueKey('none')),
          },
        ),
      ],
    );
  }
}
