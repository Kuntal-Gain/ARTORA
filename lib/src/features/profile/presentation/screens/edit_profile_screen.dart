import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/model/artist_specialties.dart';
import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/services/supabase_storage_service.dart';

/// Edits the signed-in user's photo, name, username, bio and specialties,
/// with a live preview card.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const int _nameMax = 40;
  static const int _usernameMax = 20;
  static const int _bioMax = 150;
  static const int _specialtiesMax = 5;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  Set<String> _specialties = {};
  UserModel? _original;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentUserProvider, (_, next) {
      if (next case AsyncData(:final value?) when _original == null) {
        _fill(value);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _fill(UserModel user) {
    setState(() {
      _original = user;
      _name.text = user.displayName;
      _username.text = user.username;
      _bio.text = user.bio ?? '';
      _specialties = {...?user.specialties};
    });
  }

  bool get _usernameUnchanged =>
      _username.text.trim() == _original?.username.trim();

  void _back() => context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  Future<void> _pickAvatar() => _pick(ref.read(profileAvatarProvider.notifier));

  Future<void> _pickCover() => _pick(ref.read(profileCoverProvider.notifier));

  Future<void> _pick(ProfileAvatarNotifier notifier) async {
    final failure = await notifier.pick();
    if (failure != null) {
      showGlobalToast(message: failure.message, status: 'error');
    }
  }

  String? _validateName(String? value) {
    final invalid = AppValidators.displayName(value);
    if (invalid != null) return invalid;
    return value!.trim().length > _nameMax ? '$_nameMax max' : null;
  }

  String? _validateUsername(String? value) {
    final invalid = AppValidators.username(value);
    if (invalid != null || _usernameUnchanged) return invalid;
    // Matches profile setup: the RPC answers `true` when the name is taken.
    if (ref.read(usernameAvailabilityProvider) case RequestSuccess<bool>(
      data: true,
    )) {
      return LocaleKeys.profile_setup_username_taken.tr();
    }
    return null;
  }

  /// `true` when the new username has been confirmed free (or wasn't changed).
  bool _usernameReady(RequestState<bool> availability) =>
      _usernameUnchanged ||
      availability is RequestSuccess<bool> && !availability.data;

  Future<void> _submit() async {
    if (ref.read(editProfileProvider).isLoading || _original == null) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final availability = ref.read(usernameAvailabilityProvider);
    if (!_usernameReady(availability)) {
      showGlobalToast(
        message: availability is RequestLoading
            ? LocaleKeys.profile_setup_username_checking_wait.tr()
            : LocaleKeys.profile_setup_username_not_verified.tr(),
        status: 'error',
      );
      return;
    }

    final bio = _bio.text.trim();
    final ProfileSetupParams params = (
      displayName: _name.text.trim(),
      username: _username.text.trim(),
      bio: bio.isEmpty ? null : bio,
      specialties: _specialties.toList(),
      avatar: ref.read(profileAvatarProvider),
    );
    await ref
        .read(editProfileProvider.notifier)
        .submit(params, cover: ref.read(profileCoverProvider));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider);
    final availability = ref.watch(usernameAvailabilityProvider);
    final avatarFile = ref.watch(profileAvatarProvider);
    final coverFile = ref.watch(profileCoverProvider);
    final userAsync = ref.watch(currentUserProvider);

    ref.listen(editProfileProvider, (_, next) {
      switch (next) {
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestSuccess():
          showGlobalToast(message: LocaleKeys.edit_profile_saved.tr());
          ref.invalidate(currentUserProvider);
          _back();
        case RequestInitial() || RequestLoading():
          break;
      }
    });

    final colors = context.colors;
    final busy = state.isLoading;
    final avatarUrl = SupabaseStorageService.instance.publicUrl(
      SupabaseBuckets.avatars,
      _original?.avatarPath,
    );
    final ImageProvider? avatar = avatarFile != null
        ? FileImage(avatarFile)
        : avatarUrl != null
            ? NetworkImage(avatarUrl)
            : null;
    final coverUrl = SupabaseStorageService.instance.publicUrl(
      SupabaseBuckets.banners,
      _original?.coverPath,
    );
    final ImageProvider? cover = coverFile != null
        ? FileImage(coverFile)
        : coverUrl != null
            ? NetworkImage(coverUrl)
            : null;
    // Saved values first (they may not be in the preset list), then presets.
    final options = {...?_original?.specialties, ...kArtistSpecialties}.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: _back,
        ),
        title: Text(
          LocaleKeys.edit_profile_title.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : _back,
            child: Text(
              LocaleKeys.common_cancel.tr(),
              style: context.textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: AppUploadOverlay(
        progress: ref.watch(editProfileProvider.notifier).progress,
        label: LocaleKeys.common_uploading_image.tr(),
        image: avatarFile != null
            ? FileImage(avatarFile)
            : coverFile != null
                ? FileImage(coverFile)
                : null,
        child: switch (userAsync) {
        AsyncData(value: null) || AsyncError() => AppErrorWidget(
            message: LocaleKeys.profile_load_failed.tr(),
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
        _ when _original == null => const AppLoading(),
        _ => Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
              ),
              children: [
                Center(
                  child: _AvatarPicker(
                    image: avatar,
                    enabled: !busy,
                    onTap: _pickAvatar,
                  ),
                ),
                AppSpacing.vGap(AppSpacing.lg),
                _Label(LocaleKeys.edit_profile_cover.tr()),
                AppSpacing.vGap(AppSpacing.sm),
                _CoverPicker(image: cover, enabled: !busy, onTap: _pickCover),
                AppSpacing.vGap(AppSpacing.lg),
                _Label(LocaleKeys.auth_display_name.tr(), required: true),
                AppSpacing.vGap(AppSpacing.sm),
                AppTextField(
                  hint: 'Alex Rivera',
                  controller: _name,
                  validator: _validateName,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                ),
                _Counter(length: _name.text.length, max: _nameMax),
                _Label(LocaleKeys.auth_username.tr(), required: true),
                AppSpacing.vGap(AppSpacing.sm),
                AppTextField(
                  hint: 'alexart',
                  controller: _username,
                  validator: _validateUsername,
                  enabled: !busy,
                  status: _usernameUnchanged
                      ? AppFieldStatus.none
                      : switch (availability) {
                          RequestSuccess(data: false) => AppFieldStatus.success,
                          RequestSuccess(data: true) => AppFieldStatus.error,
                          _ => AppFieldStatus.none,
                        },
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      '@',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (!_usernameUnchanged) {
                      ref
                          .read(usernameAvailabilityProvider.notifier)
                          .onChanged(value);
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: _UsernameHint(
                        availability:
                            _usernameUnchanged ? null : availability,
                      ),
                    ),
                    _Counter(length: _username.text.length, max: _usernameMax),
                  ],
                ),
                _Label(LocaleKeys.profile_setup_bio.tr()),
                AppSpacing.vGap(AppSpacing.sm),
                AppTextArea(
                  hint: LocaleKeys.profile_setup_bio_hint.tr(),
                  controller: _bio,
                  maxLength: _bioMax,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                ),
                AppSpacing.vGap(AppSpacing.formFieldGap),
                _Label(
                  LocaleKeys.profile_setup_specialties.tr(),
                  suffix: LocaleKeys.edit_profile_specialties_max.tr(
                    namedArgs: {'max': '$_specialtiesMax'},
                  ),
                ),
                AppSpacing.vGap(AppSpacing.sm),
                IgnorePointer(
                  ignoring: busy,
                  child: AppChipSelect(
                    options: options,
                    selected: _specialties,
                    maxSelected: _specialtiesMax,
                    onChanged: (next) => setState(() => _specialties = next),
                  ),
                ),
                AppSpacing.vGap(AppSpacing.lg),
                _Label(LocaleKeys.edit_profile_preview.tr()),
                AppSpacing.vGap(AppSpacing.sm),
                _PreviewCard(
                  image: avatar,
                  name: _name.text.trim(),
                  username: _username.text.trim(),
                  bio: _bio.text.trim(),
                  specialties: _specialties.toList(),
                ),
                AppSpacing.vGap(AppSpacing.lg),
                AppButton(
                  label: LocaleKeys.edit_profile_save.tr(),
                  isFullWidth: true,
                  isLoading: busy,
                  onPressed: busy ? null : _submit,
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// Field heading with an optional red `*` and muted suffix.
class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false, this.suffix});

  final String text;
  final bool required;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textTheme.labelLarge;
    return Text.rich(
      TextSpan(
        text: text,
        style: style?.copyWith(color: colors.onSurface),
        children: [
          if (required)
            TextSpan(text: ' *', style: style?.copyWith(color: colors.error)),
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: style?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Right-aligned `length/max` under a field.
class _Counter extends StatelessWidget {
  const _Counter({required this.length, required this.max});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$length/$max',
          style: context.textTheme.bodySmall?.copyWith(
            color: length > max ? colors.error : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// "Checking…" / "Username is available" / "taken" under the username field;
/// empty when [availability] is `null` (username unchanged).
class _UsernameHint extends StatelessWidget {
  const _UsernameHint({required this.availability});

  final RequestState<bool>? availability;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (text, color) = switch (availability) {
      RequestLoading() => (
          LocaleKeys.profile_setup_username_checking.tr(),
          colors.onSurfaceVariant,
        ),
      RequestSuccess(data: false) => (
          LocaleKeys.edit_profile_username_available.tr(),
          context.appColors.success,
        ),
      RequestSuccess(data: true) => (
          LocaleKeys.profile_setup_username_taken.tr(),
          colors.error,
        ),
      _ => (null, null),
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

/// Round photo with a camera badge plus the caption and file-type hint.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.image,
    required this.enabled,
    required this.onTap,
  });

  final ImageProvider? image;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = 104.r;
    final caption = LocaleKeys.edit_profile_tap_to_change.tr();

    return Semantics(
      button: true,
      label: caption,
      child: InkResponse(
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _Avatar(image: image, size: size, borderWidth: 3.r),
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
                        AppIcons.camera,
                        size: 16.r,
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
            Text(
              LocaleKeys.edit_profile_photo_hint.tr(),
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide cover banner with a "Change cover" pill; empty state is a tinted box.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.image,
    required this.enabled,
    required this.onTap,
  });

  final ImageProvider? image;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = LocaleKeys.edit_profile_change_cover.tr();
    final radius = BorderRadius.circular(AppSpacing.md);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            image: image == null
                ? null
                : DecorationImage(image: image!, fit: BoxFit.cover),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Align(
                alignment: image == null
                    ? Alignment.center
                    : Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppSpacing.lg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.camera, size: 16.r, color: colors.primary),
                        AppSpacing.hGap(AppSpacing.xs),
                        Text(
                          label,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.image,
    required this.size,
    required this.borderWidth,
  });

  final ImageProvider? image;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.primary, width: borderWidth),
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image == null
          ? Icon(AppIcons.person, size: size / 2.4, color: colors.onSurfaceVariant)
          : null,
    );
  }
}

/// How the profile will look to others, updated as the user types.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.image,
    required this.name,
    required this.username,
    required this.bio,
    required this.specialties,
  });

  final ImageProvider? image;
  final String name;
  final String username;
  final String bio;
  final List<String> specialties;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(image: image, size: 64.r, borderWidth: 2.r),
              AppSpacing.hGap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: tt.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (bio.isNotEmpty) ...[
                      AppSpacing.vGap(AppSpacing.xs),
                      Text(
                        bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: colors.onSurface),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (specialties.isNotEmpty) ...[
            AppSpacing.vGap(AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in specialties)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.lg),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      s,
                      style: tt.labelSmall?.copyWith(color: colors.primary),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
