import 'dart:io';

import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/model/artist_specialties.dart';
import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:artora/src/imports/imports.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const int _bioMaxLength = 150;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final Set<String> _specialties = {};

  @override
  void initState() {
    super.initState();
    ref.listenManual(signUpPrefillProvider, (_, next) {
      if (next case AsyncData(:final value?)) _applyPrefill(value);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Fills the fields from sign-up without overwriting anything already typed.
  void _applyPrefill(SignUpPrefill prefill) {
    final name = prefill.name;
    if (name != null && name.isNotEmpty && _name.text.isEmpty) {
      _name.text = name;
    }
    final username = prefill.username;
    if (username != null && username.isNotEmpty && _username.text.isEmpty) {
      _username.text = username;
      ref.read(usernameAvailabilityProvider.notifier).onChanged(username);
    }
  }

  Future<void> _pickAvatar() async {
    final failure = await ref.read(profileAvatarProvider.notifier).pick();
    if (failure != null) {
      showGlobalToast(message: failure.message, status: 'error');
    }
  }

  void _toggleSpecialty(String specialty, bool selected) {
    setState(() {
      if (selected) {
        _specialties.add(specialty);
      } else {
        _specialties.remove(specialty);
      }
    });
  }

  String? _validateUsername(String? value) {
    final invalid = AppValidators.username(value);
    if (invalid != null) return invalid;
    final availability = ref.read(usernameAvailabilityProvider);
    if (availability case RequestSuccess(data: false)) {
      return LocaleKeys.profile_setup_username_taken.tr();
    }
    return null;
  }

  AppFieldStatus _usernameStatus(RequestState<bool> availability) =>
      switch (availability) {
        RequestSuccess(data: true) => AppFieldStatus.success,
        RequestSuccess(data: false) => AppFieldStatus.error,
        RequestInitial() ||
        RequestLoading() ||
        RequestSuccess() ||
        RequestFailure() => AppFieldStatus.none,
      };

  // Profile isn't saved yet: Continue goes straight to the home feed.
  void _submit() {
    FocusScope.of(context).unfocus();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupProvider);
    final availability = ref.watch(usernameAvailabilityProvider);
    final avatar = ref.watch(profileAvatarProvider);

    ref.listen(profileSetupProvider, (_, next) {
      switch (next) {
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestSuccess():
          showGlobalToast(message: LocaleKeys.profile_setup_saved.tr());
          context.go(AppRoutes.home);
        case RequestInitial() || RequestLoading():
          break;
      }
    });

    final colors = context.colors;

    return AuthScaffold(
      title: LocaleKeys.profile_setup_title.tr(),
      subtitle: LocaleKeys.profile_setup_subtitle.tr(),
      showBack: false,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _AvatarPicker(
                  file: avatar,
                  enabled: !state.isLoading,
                  onTap: _pickAvatar,
                ),
              ),
              AppSpacing.vGap(AppSpacing.lg),
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
                validator: _validateUsername,
                status: _usernameStatus(availability),
                onChanged: (value) => ref
                    .read(usernameAvailabilityProvider.notifier)
                    .onChanged(value),
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.formFieldGap),
              _OptionalLabel(label: LocaleKeys.profile_setup_bio.tr()),
              AppSpacing.vGap(AppSpacing.sm),
              AppTextArea(
                hint: LocaleKeys.profile_setup_bio_hint.tr(),
                controller: _bio,
                maxLength: _bioMaxLength,
                enabled: !state.isLoading,
              ),
              AppSpacing.vGap(AppSpacing.formFieldGap),
              _OptionalLabel(label: LocaleKeys.profile_setup_specialties.tr()),
              AppSpacing.vGap(AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final specialty in kArtistSpecialties)
                    AppChip(
                      label: specialty,
                      selected: _specialties.contains(specialty),
                      onSelected: state.isLoading
                          ? null
                          : (selected) => _toggleSpecialty(specialty, selected),
                    ),
                ],
              ),
              AppSpacing.vGap(AppSpacing.lg),
              AppButton(
                label: LocaleKeys.profile_setup_continue_button.tr(),
                isFullWidth: true,
                height: ButtonSize.small,
                isLoading: state.isLoading,
                suffixIcon: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18.r,
                  color: colors.onPrimary,
                ),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Label (Optional)" heading used above the bio and specialties inputs.
class _OptionalLabel extends StatelessWidget {
  const _OptionalLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.labelLarge;

    return Text.rich(
      TextSpan(
        text: label,
        style: style?.copyWith(color: colors.onSurface),
        children: [
          TextSpan(
            text: ' ${LocaleKeys.profile_setup_optional.tr()}',
            style: style?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Round photo with a camera badge; shows [file] once one is chosen.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.file,
    required this.enabled,
    required this.onTap,
  });

  final File? file;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = 112.r;
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();

    final caption = LocaleKeys.profile_setup_tap_to_upload.tr();

    return Semantics(
      button: true,
      label: caption,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceContainerHighest,
                      border: Border.all(color: colors.primary, width: 3.r),
                    ),
                    child: ClipOval(
                      child: file != null
                          ? Image.file(
                              file!,
                              fit: BoxFit.cover,
                              cacheWidth: cacheWidth,
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              size: 48.r,
                              color: colors.onSurfaceVariant,
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2.r,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 18.r,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGap(AppSpacing.sm),
            Text(
              caption,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
