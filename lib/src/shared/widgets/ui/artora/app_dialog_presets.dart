import '../../../../imports/imports.dart';

/// Ready-made confirmation dialogs (see [showAppAlertDialog]). Each completes
/// with `true` only if the user confirmed.
abstract final class AppDialogPresets {
  AppDialogPresets._();

  static Future<bool?> deleteArtwork(BuildContext context) =>
      showAppAlertDialog(
        context,
        icon: AppIcons.delete,
        title: LocaleKeys.editor_delete_title.tr(),
        message: LocaleKeys.editor_delete_message.tr(),
        confirmLabel: LocaleKeys.common_delete.tr(),
        cancelLabel: LocaleKeys.common_cancel.tr(),
        isDestructive: true,
      );

  static Future<bool?> signOut(BuildContext context) => showAppAlertDialog(
        context,
        icon: AppIcons.logout,
        title: LocaleKeys.settings_sign_out_title.tr(),
        message: LocaleKeys.settings_sign_out_message.tr(),
        confirmLabel: LocaleKeys.settings_sign_out.tr(),
        cancelLabel: LocaleKeys.common_cancel.tr(),
        isDestructive: true,
      );

  static Future<bool?> blockUser(BuildContext context, String username) =>
      showAppAlertDialog(
        context,
        icon: AppIcons.block,
        title: LocaleKeys.block_title.tr(namedArgs: {'username': username}),
        message: LocaleKeys.block_message.tr(),
        confirmLabel: LocaleKeys.block_confirm.tr(),
        cancelLabel: LocaleKeys.common_cancel.tr(),
        isDestructive: true,
      );

  static Future<bool?> signOutDevice(BuildContext context) =>
      showAppAlertDialog(
        context,
        icon: AppIcons.logout,
        title: LocaleKeys.account_settings_device_sign_out_title.tr(),
        message: LocaleKeys.account_settings_device_sign_out_message.tr(),
        confirmLabel: LocaleKeys.settings_sign_out.tr(),
        cancelLabel: LocaleKeys.common_cancel.tr(),
        isDestructive: true,
      );

  static Future<bool?> signOutOtherDevices(BuildContext context) =>
      showAppAlertDialog(
        context,
        icon: AppIcons.logout,
        title: LocaleKeys.account_settings_others_sign_out_title.tr(),
        message: LocaleKeys.account_settings_others_sign_out_message.tr(),
        confirmLabel: LocaleKeys.settings_sign_out.tr(),
        cancelLabel: LocaleKeys.common_cancel.tr(),
        isDestructive: true,
      );

  static Future<bool?> deleteAccount(BuildContext context) =>
      showAppAlertDialog(
        context,
        icon: AppIcons.warning,
        title: LocaleKeys.settings_delete_account_title.tr(),
        message: LocaleKeys.settings_delete_account_message.tr(),
        confirmLabel: LocaleKeys.settings_delete_account.tr(),
        cancelLabel: LocaleKeys.common_cancel.tr(),
        isDestructive: true,
      );
}
