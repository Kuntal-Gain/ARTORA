import '../../../../../imports/imports.dart';

/// Validation status shown on [AppTextField] outside of form validation.
enum AppFieldStatus { none, success, error }

/// Themed text field with Material / Cupertino chrome.
///
/// Use [status] + [errorText] to drive success / error visuals from state
/// (e.g. username availability); [validator] still works inside an [AppForm].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.initialValue,
    this.autofocus = false,
    this.status = AppFieldStatus.none,
    this.errorText,
    this.platform,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? initialValue;
  final bool autofocus;
  final AppFieldStatus status;
  final String? errorText;
  final AppPlatformStyle? platform;

  @override
  Widget build(BuildContext context) {
    final useCupertino = context.resolveCupertinoUi(platform);
    final cs = context.colors;

    if (useCupertino) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: context.textTheme.labelLarge),
            SizedBox(height: AppSpacing.xs),
          ],
          CupertinoTextField(
            controller: controller,
            placeholder: hint,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            readOnly: readOnly,
            enabled: enabled,
            maxLines: maxLines,
            minLines: minLines,
            prefix: prefixIcon,
            suffix: suffixIcon,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onFieldSubmitted,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.ms,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: AppBorders.input,
              border: Border.all(color: cs.outlineVariant),
            ),
          ),
        ],
      );
    }

    final success = context.appColors.success;
    final isSuccess = status == AppFieldStatus.success;
    final isError = status == AppFieldStatus.error || errorText != null;
    final successBorder = OutlineInputBorder(
      borderRadius: AppBorders.input,
      borderSide: BorderSide(color: success),
    );
    final statusIcon = isSuccess
        ? Icon(Icons.check_circle_rounded, color: success, size: 20.sp)
        : isError
            ? Icon(Icons.error_rounded, color: cs.error, size: 20.sp)
            : null;

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon ?? statusIcon,
        errorText: errorText,
        enabledBorder: isSuccess ? successBorder : null,
        focusedBorder: isSuccess ? successBorder : null,
      ),
    );
  }
}
