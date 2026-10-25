import 'package:flutter/gestures.dart';

import '../../../../imports/imports.dart';

/// A single password / form rule with its current state.
typedef AppRequirement = ({String label, bool met});

/// Live checklist of password rules.
///
/// Usage:
/// ```dart
/// AppPasswordRequirements(password: _passwordController.text)
/// ```
/// Pass [requirements] to show a fully custom list.
class AppPasswordRequirements extends StatelessWidget {
  const AppPasswordRequirements({
    super.key,
    this.password = '',
    this.requirements,
  });

  final String password;
  final List<AppRequirement>? requirements;

  List<AppRequirement> get _rules =>
      requirements ??
      [
        (label: 'At least 8 characters', met: password.length >= 8),
        (label: 'Include a number', met: RegExp(r'\d').hasMatch(password)),
        (label: 'Include a letter', met: RegExp(r'[A-Za-z]').hasMatch(password)),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final success = context.appColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in _rules)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Icon(
                    rule.met
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(rule.met),
                    size: 16.sp,
                    color: rule.met ? success : cs.onSurfaceVariant,
                  ),
                ),
                AppSpacing.hGap(AppSpacing.sm),
                Text(
                  rule.label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: rule.met ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Checkbox with "I agree to the Terms of Service and Privacy Policy" label.
///
/// Usage:
/// ```dart
/// AppTermsCheckbox(
///   value: accepted,
///   onChanged: (v) => setState(() => accepted = v),
///   onTermsTap: _openTerms,
///   onPrivacyTap: _openPrivacy,
/// )
/// ```
class AppTermsCheckbox extends StatefulWidget {
  const AppTermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  @override
  State<AppTermsCheckbox> createState() => _AppTermsCheckboxState();
}

class _AppTermsCheckboxState extends State<AppTermsCheckbox> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()..onTap = () => widget.onTermsTap?.call();
    _privacy = TapGestureRecognizer()..onTap = () => widget.onPrivacyTap?.call();
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final base = context.textTheme.bodySmall?.copyWith(color: cs.onSurface);
    final link = base?.copyWith(
      color: cs.primary,
      decoration: TextDecoration.underline,
      decorationColor: cs.primary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCheckbox(
          value: widget.value,
          onChanged: (v) => widget.onChanged(v ?? false),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(text: 'Terms of Service', style: link, recognizer: _terms),
                  const TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Multi-select chip group with check marks (e.g. creative specialties).
///
/// Usage:
/// ```dart
/// AppChipSelect(
///   options: const ['Illustration', 'Concept Art'],
///   selected: selected,
///   onChanged: (s) => setState(() => selected = s),
/// )
/// ```
class AppChipSelect extends StatelessWidget {
  const AppChipSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.maxSelected,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final int? maxSelected;

  void _toggle(String option, bool on) {
    final next = {...selected};
    if (on) {
      if (maxSelected != null && next.length >= maxSelected!) return;
      next.add(option);
    } else {
      next.remove(option);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          AppChip(
            label: option,
            selected: selected.contains(option),
            onSelected: (on) => _toggle(option, on),
          ),
      ],
    );
  }
}
