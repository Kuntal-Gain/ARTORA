import 'package:easy_localization/easy_localization.dart';

import '../../core/i18n/locale_keys.g.dart';

/// Live password requirement results, used by validators and the checklist.
typedef PasswordChecks = ({bool minLength, bool hasNumber, bool hasLetter});

/// Reusable form validators. Each returns a localized message,
/// or `null` when the value is valid.
abstract final class AppValidators {
  AppValidators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _username = RegExp(r'^[A-Za-z0-9_]{3,20}$');

  static bool isValidEmail(String? value) =>
      _email.hasMatch((value ?? '').trim());

  static bool isValidUsername(String? value) =>
      _username.hasMatch((value ?? '').trim());

  static PasswordChecks checkPassword(String value) => (
        minLength: value.length >= 8,
        hasNumber: value.contains(RegExp(r'\d')),
        hasLetter: value.contains(RegExp(r'[A-Za-z]')),
      );

  static String? email(String? value) {
    if ((value ?? '').trim().isEmpty) return LocaleKeys.auth_email_required.tr();
    return isValidEmail(value) ? null : LocaleKeys.auth_email_invalid.tr();
  }

  /// Sign-in only checks presence; strength rules apply at sign-up.
  static String? passwordRequired(String? value) =>
      (value ?? '').isEmpty ? LocaleKeys.auth_password_required.tr() : null;

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return LocaleKeys.auth_password_required.tr();
    final checks = checkPassword(v);
    final ok = checks.minLength && checks.hasNumber && checks.hasLetter;
    return ok ? null : LocaleKeys.auth_password_rules_unmet.tr();
  }

  static String? displayName(String? value) => (value ?? '').trim().isEmpty
      ? LocaleKeys.auth_display_name_required.tr()
      : null;

  static String? username(String? value) =>
      isValidUsername(value) ? null : LocaleKeys.auth_username_invalid.tr();
}
