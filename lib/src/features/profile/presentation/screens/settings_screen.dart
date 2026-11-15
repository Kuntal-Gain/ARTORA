import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/shared/widgets/language_picker.dart';

/// Account, privacy, app and support settings, plus sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // shortcut: hardcoded to match pubspec; read it via package_info_plus if
  // versions start changing often.
  static const _version = '1.0.0';

  void _comingSoon() =>
      showGlobalToast(message: LocaleKeys.common_coming_soon.tr());

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogPresets.signOut(context);
    if (confirmed != true) return;
    await ref.read(signOutProvider.notifier).submit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(signOutProvider, (_, next) {
      switch (next) {
        case RequestSuccess():
          context.go(AppRoutes.login);
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestInitial() || RequestLoading():
          break;
      }
    });
    final signingOut = ref.watch(signOutProvider).isLoading;
    final language = supportedLanguageNames[context.locale.languageCode] ??
        context.locale.languageCode;

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
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        title: Text(
          LocaleKeys.settings_title.tr(),
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
          _Section(
            title: LocaleKeys.settings_account.tr(),
            items: [
              _Item(
                icon: AppIcons.person,
                title: LocaleKeys.settings_account_settings.tr(),
                subtitle: LocaleKeys.settings_account_settings_sub.tr(),
                onTap: _comingSoon,
              ),
              _Item(
                icon: AppIcons.userEdit,
                title: LocaleKeys.settings_edit_profile.tr(),
                subtitle: LocaleKeys.settings_edit_profile_sub.tr(),
                onTap: _comingSoon,
              ),
            ],
          ),
          _Section(
            title: LocaleKeys.settings_privacy_safety.tr(),
            items: [
              _Item(
                icon: AppIcons.lock,
                title: LocaleKeys.settings_privacy.tr(),
                subtitle: LocaleKeys.settings_privacy_sub.tr(),
                onTap: _comingSoon,
              ),
              _Item(
                icon: AppIcons.block,
                title: LocaleKeys.settings_blocked_users.tr(),
                subtitle: LocaleKeys.settings_blocked_users_sub.tr(),
                onTap: _comingSoon,
              ),
              _Item(
                icon: AppIcons.warning,
                title: LocaleKeys.settings_reported_content.tr(),
                subtitle: LocaleKeys.settings_reported_content_sub.tr(),
                onTap: _comingSoon,
              ),
            ],
          ),
          _Section(
            title: LocaleKeys.settings_app.tr(),
            items: [
              _Item(
                icon: AppIcons.notifications,
                title: LocaleKeys.settings_notifications.tr(),
                subtitle: LocaleKeys.settings_notifications_sub.tr(),
                onTap: _comingSoon,
              ),
              _Item(
                icon: AppIcons.appearance,
                title: LocaleKeys.settings_appearance.tr(),
                subtitle: LocaleKeys.settings_appearance_sub.tr(),
                onTap: _comingSoon,
              ),
              _Item(
                icon: AppIcons.language,
                title: LocaleKeys.settings_language.tr(),
                subtitle: language,
                onTap: () => showLanguagePicker(context),
              ),
            ],
          ),
          _Section(
            title: LocaleKeys.settings_support.tr(),
            items: [
              _Item(
                icon: AppIcons.help,
                title: LocaleKeys.settings_help_support.tr(),
                subtitle: LocaleKeys.settings_help_support_sub.tr(),
                onTap: _comingSoon,
              ),
              _Item(
                icon: AppIcons.info,
                title: LocaleKeys.settings_about.tr(),
                subtitle: LocaleKeys.settings_version.tr(
                  namedArgs: {'version': _version},
                ),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: LocaleKeys.app_name.tr(),
                  applicationVersion: _version,
                ),
              ),
            ],
          ),
          AppSpacing.vGap(AppSpacing.sm),
          _SignOutTile(
            loading: signingOut,
            onTap: signingOut ? null : () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}

class _Item {
  const _Item({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// Section heading plus one bordered card holding its rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: AppBorders.md,
              side: BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (index, item) in items.indexed) ...[
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.border),
                  _Row(item: item),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 24.r, color: AppColors.primary),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.vGap(AppSpacing.xs),
                  Text(
                    item.subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: 20.r,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.md,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(AppIcons.logout, size: 24.r, color: AppColors.error),
              AppSpacing.hGap(AppSpacing.md),
              Expanded(
                child: Text(
                  LocaleKeys.settings_sign_out.tr(),
                  style: context.textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (loading)
                SizedBox.square(
                  dimension: 18.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              else
                Icon(
                  AppIcons.chevronRight,
                  size: 20.r,
                  color: AppColors.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
