import 'package:artora/src/imports/imports.dart';

/// Language codes the app ships with, shown in their own language.
const supportedLanguageNames = {'en': 'English', 'ja': '日本語'};

/// Bottom sheet to switch the app language; applies the choice immediately.
Future<void> showLanguagePicker(BuildContext context) async {
  final code = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final MapEntry(:key, :value) in supportedLanguageNames.entries)
            ListTile(
              title: Text(
                value,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: context.locale.languageCode == key
                  ? const Icon(AppIcons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(key),
            ),
        ],
      ),
    ),
  );
  if (code != null && context.mounted) {
    await context.setLocale(Locale(code));
  }
}
