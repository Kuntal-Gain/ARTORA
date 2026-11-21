import 'package:artora/src/features/auth/model/account_session.dart';
import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:artora/src/imports/imports.dart';

/// Account settings: the email (view only), change password, and the devices
/// signed in to the account.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(changePasswordProvider.notifier)
        .submit(_current.text, _new.text);
  }

  Future<void> _revoke(AccountSession session) async {
    if (await AppDialogPresets.signOutDevice(context) != true) return;
    await ref.read(sessionActionsProvider.notifier).revoke(session.id);
  }

  Future<void> _signOutOthers() async {
    if (await AppDialogPresets.signOutOtherDevices(context) != true) return;
    await ref.read(sessionActionsProvider.notifier).signOutOthers();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(changePasswordProvider, (_, next) {
      switch (next) {
        case RequestSuccess():
          _current.clear();
          _new.clear();
          _confirm.clear();
          showGlobalToast(
            message: LocaleKeys.account_settings_password_updated.tr(),
          );
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestInitial() || RequestLoading():
          break;
      }
    });
    ref.listen(sessionActionsProvider, (_, next) {
      switch (next) {
        case RequestSuccess():
          showGlobalToast(
            message: LocaleKeys.account_settings_device_signed_out.tr(),
          );
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestInitial() || RequestLoading():
          break;
      }
    });

    final email = AppConfig.supabase.auth.currentUser?.email ?? '';
    final changing = ref.watch(changePasswordProvider).isLoading;
    final sessions = ref.watch(accountSessionsProvider);
    final signingOut = ref.watch(sessionActionsProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.settings),
        ),
        title: Text(
          LocaleKeys.account_settings_title.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        children: [
          // ── Email: view only ──
          _Heading(LocaleKeys.account_settings_email_section.tr()),
          AppSpacing.vGap(AppSpacing.sm),
          AppTextField(
            key: ValueKey(email),
            initialValue: email,
            readOnly: true,
            prefixIcon: const Icon(AppIcons.mail),
            suffixIcon: const Icon(AppIcons.lock),
          ),
          AppSpacing.vGap(AppSpacing.xs),
          Text(
            LocaleKeys.account_settings_email_readonly.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap(AppSpacing.xl),

          // ── Change password ──
          _Heading(LocaleKeys.account_settings_password_section.tr()),
          AppSpacing.vGap(AppSpacing.md),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthField(
                  label: LocaleKeys.account_settings_current_password.tr(),
                  controller: _current,
                  icon: const Icon(AppIcons.lock),
                  obscure: true,
                  validator: AppValidators.passwordRequired,
                  enabled: !changing,
                ),
                AppSpacing.vGap(AppSpacing.formFieldGap),
                AuthField(
                  label: LocaleKeys.account_settings_new_password.tr(),
                  controller: _new,
                  icon: const Icon(AppIcons.lock),
                  obscure: true,
                  validator: AppValidators.newPassword,
                  enabled: !changing,
                ),
                AppSpacing.vGap(AppSpacing.formFieldGap),
                AuthField(
                  label: LocaleKeys.account_settings_confirm_new_password.tr(),
                  controller: _confirm,
                  icon: const Icon(AppIcons.lock),
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _changePassword(),
                  validator: (value) => (value ?? '').isEmpty
                      ? LocaleKeys.auth_confirm_password_required.tr()
                      : value != _new.text
                          ? LocaleKeys.auth_passwords_do_not_match.tr()
                          : null,
                  enabled: !changing,
                ),
                AppSpacing.vGap(AppSpacing.lg),
                AppButton(
                  label: LocaleKeys.account_settings_update_password.tr(),
                  isFullWidth: true,
                  isLoading: changing,
                  onPressed: changing ? null : _changePassword,
                ),
              ],
            ),
          ),
          AppSpacing.vGap(AppSpacing.xl),

          // ── Active sessions ──
          _Heading(LocaleKeys.account_settings_sessions_section.tr()),
          AppSpacing.vGap(AppSpacing.xs),
          Text(
            LocaleKeys.account_settings_sessions_hint.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGap(AppSpacing.md),
          switch (sessions) {
            AsyncData(:final value) => _SessionList(
                sessions: value,
                busy: signingOut,
                onRevoke: _revoke,
                onSignOutOthers: _signOutOthers,
              ),
            AsyncError() => AppErrorWidget(
                message: LocaleKeys.account_settings_sessions_failed.tr(),
                onRetry: () => ref.invalidate(accountSessionsProvider),
              ),
            _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AppLoading(),
              ),
          },
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.sessions,
    required this.busy,
    required this.onRevoke,
    required this.onSignOutOthers,
  });

  final List<AccountSession> sessions;
  final bool busy;
  final void Function(AccountSession session) onRevoke;
  final VoidCallback onSignOutOthers;

  @override
  Widget build(BuildContext context) {
    final hasOthers = sessions.any((s) => !s.isCurrent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final session in sessions) ...[
          _SessionTile(
            session: session,
            busy: busy,
            onRevoke: () => onRevoke(session),
          ),
          AppSpacing.vGap(AppSpacing.sm),
        ],
        if (!hasOthers)
          Text(
            LocaleKeys.account_settings_no_other_devices.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        else ...[
          AppSpacing.vGap(AppSpacing.sm),
          AppButton(
            label: LocaleKeys.account_settings_sign_out_others.tr(),
            variant: ButtonVariant.outline,
            isFullWidth: true,
            onPressed: busy ? null : onSignOutOthers,
          ),
        ],
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.busy,
    required this.onRevoke,
  });

  final AccountSession session;
  final bool busy;
  final VoidCallback onRevoke;

  /// A readable name from the user agent. The app's own requests identify as
  /// "Dart/…", which says nothing about the phone, so those show as the app.
  String _device() {
    final ua = (session.userAgent ?? '').toLowerCase();
    if (ua.contains('iphone') || ua.contains('ipad')) return 'iPhone / iPad';
    if (ua.contains('android')) return 'Android';
    if (ua.contains('windows')) return 'Windows';
    if (ua.contains('mac os') || ua.contains('macintosh')) return 'Mac';
    if (ua.contains('linux')) return 'Linux';
    if (ua.contains('dart')) return LocaleKeys.account_settings_app_device.tr();
    return LocaleKeys.account_settings_unknown_device.tr();
  }

  /// "now", "5m ago", "2h ago", "3d ago", "2w ago", then the date.
  String _ago() {
    final d = DateTime.now().difference(session.updatedAt);
    if (d.inMinutes < 1) return LocaleKeys.notifications_time_now.tr();
    String ago(String key, int n) => key.tr(namedArgs: {'count': '$n'});
    if (d.inHours < 1) {
      return ago(LocaleKeys.notifications_time_minutes, d.inMinutes);
    }
    if (d.inDays < 1) return ago(LocaleKeys.notifications_time_hours, d.inHours);
    if (d.inDays < 7) return ago(LocaleKeys.notifications_time_days, d.inDays);
    if (d.inDays < 30) {
      return ago(LocaleKeys.notifications_time_weeks, d.inDays ~/ 7);
    }
    final t = session.updatedAt;
    return '${t.year}/${t.month.toString().padLeft(2, '0')}/'
        '${t.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final details = [
      LocaleKeys.account_settings_active.tr(namedArgs: {'when': _ago()}),
      if ((session.ip ?? '').isNotEmpty) session.ip!,
    ].join(' · ');

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.lg,
        border: Border.all(
          color: session.isCurrent ? colors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _device(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (session.isCurrent) ...[
                      AppSpacing.hGap(AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2.r,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.14),
                          borderRadius: AppBorders.full,
                        ),
                        child: Text(
                          LocaleKeys.account_settings_this_device.tr(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.vGap(AppSpacing.xs),
                Text(
                  details,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // This device signs out with the normal Sign out in Settings.
          if (!session.isCurrent)
            IconButton(
              tooltip: LocaleKeys.settings_sign_out.tr(),
              onPressed: busy ? null : onRevoke,
              icon: Icon(AppIcons.logout, color: colors.error),
            ),
        ],
      ),
    );
  }
}
