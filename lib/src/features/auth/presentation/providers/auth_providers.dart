import 'dart:async';
import 'dart:io';

import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/data/auth_usecase_impl.dart';
import 'package:artora/src/features/auth/model/account_session.dart';
import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/imports/imports.dart';

typedef LoginParams = ({String email, String password});
typedef SignUpParams = ({
  String name,
  String username,
  String email,
  String password,
});

final authUsecaseProvider = Provider<AuthUsecase>((ref) => AuthUsecaseImpl());

/// Success data is `true` when the account has no profile yet and must go
/// through profile setup.
class LoginNotifier extends StateNotifier<RequestState<bool>> {
  LoginNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit(LoginParams params) async {
    state = const RequestLoading();
    final signedIn = await _usecase.signIn(
      email: params.email,
      password: params.password,
    );
    if (!mounted) return;
    if (signedIn case ResourceError<void>(:final failure)) {
      state = RequestFailure(failure);
      return;
    }

    final profile = await _usecase.hasProfile();
    if (!mounted) return;
    state = switch (profile) {
      ResourceSuccess<bool>(:final data) => RequestSuccess(!data),
      ResourceError<bool>(:final failure) => RequestFailure(failure),
      ResourceLoading<bool>() => const RequestLoading(),
    };
  }
}

class SignUpNotifier extends StateNotifier<RequestState<void>> {
  SignUpNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit(SignUpParams params) async {
    state = const RequestLoading();
    final result = await _usecase.signUp(
      name: params.name,
      username: params.username,
      email: params.email,
      password: params.password,
    );
    if (!mounted) return;
    state = result.toRequestState();
  }
}

class ForgotPasswordNotifier extends StateNotifier<RequestState<void>> {
  ForgotPasswordNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit(String email) async {
    state = const RequestLoading();
    final result = await _usecase.forgotPassword(email: email);
    if (!mounted) return;
    state = result.toRequestState();
  }
}

class SignOutNotifier extends StateNotifier<RequestState<void>> {
  SignOutNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit() async {
    state = const RequestLoading();
    final result = await _usecase.signOut();
    if (!mounted) return;
    state = result.toRequestState();
  }
}

class ProfileSetupNotifier extends StateNotifier<RequestState<void>> {
  ProfileSetupNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit(ProfileSetupParams params) async {
    state = const RequestLoading();
    final result = await _usecase.setupProfile(params);
    if (!mounted) return;
    state = result.toRequestState();
  }
}

class EditProfileNotifier extends StateNotifier<RequestState<void>> {
  EditProfileNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  /// Photo upload progress (0–1); `null` when nothing is uploading.
  final progress = ValueNotifier<double?>(null);

  Future<void> submit(ProfileSetupParams params, {File? cover}) async {
    state = const RequestLoading();
    final result = await _usecase.updateProfile(
      params,
      cover: cover,
      onProgress: (p) {
        if (mounted) progress.value = p;
      },
    );
    if (!mounted) return;
    progress.value = null;
    state = result.toRequestState();
  }

  @override
  void dispose() {
    progress.dispose();
    super.dispose();
  }
}

class ChangePasswordNotifier extends StateNotifier<RequestState<void>> {
  ChangePasswordNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit(String currentPassword, String newPassword) async {
    state = const RequestLoading();
    final result = await _usecase.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!mounted) return;
    state = result.toRequestState();
  }
}

/// Signing devices out; [onChanged] reloads the sessions list afterwards.
class SessionActionsNotifier extends StateNotifier<RequestState<void>> {
  SessionActionsNotifier(this._usecase, {required void Function() onChanged})
      : _onChanged = onChanged,
        super(const RequestInitial());

  final AuthUsecase _usecase;
  final void Function() _onChanged;

  Future<void> revoke(String sessionId) =>
      _run(() => _usecase.revokeSession(sessionId));

  Future<void> signOutOthers() => _run(_usecase.signOutOtherDevices);

  Future<void> _run(Future<Resource<void>> Function() action) async {
    if (state.isLoading) return;
    state = const RequestLoading();
    final result = await action();
    if (!mounted) return;
    state = result.toRequestState();
    if (state is RequestSuccess<void>) _onChanged();
  }
}

/// Holds a photo (avatar or cover) chosen on the profile setup / edit screen.
class ProfileAvatarNotifier extends StateNotifier<File?> {
  ProfileAvatarNotifier(this._pick) : super(null);

  final Future<Resource<File?>> Function() _pick;

  /// Returns the failure to show, or `null` when a photo was chosen or the
  /// picker was dismissed (the previous photo is kept in that case).
  Future<Failure?> pick() async {
    final result = await _pick();
    if (!mounted) return null;
    switch (result) {
      case ResourceSuccess<File?>(:final data):
        if (data != null) state = data;
        return null;
      case ResourceError<File?>(:final failure):
        return failure;
      case ResourceLoading<File?>():
        return null;
    }
  }
}

/// Debounced username availability: success data is `true` when it is free.
class UsernameAvailabilityNotifier extends StateNotifier<RequestState<bool>> {
  UsernameAvailabilityNotifier(this._usecase) : super(const RequestInitial());

  static const Duration _debounce = Duration(milliseconds: 500);

  final AuthUsecase _usecase;
  Timer? _timer;
  String _latest = '';

  void onChanged(String raw) {
    final username = raw.trim();
    _latest = username;
    _timer?.cancel();

    if (!AppValidators.isValidUsername(username)) {
      state = const RequestInitial();
      return;
    }
    state = const RequestLoading();
    _timer = Timer(_debounce, () => _check(username));
  }

  Future<void> _check(String username) async {
    final result = await _usecase.isUsernameAvailable(username);
    // Ignore answers for a username the user has already edited away from.
    if (!mounted || username != _latest) return;
    state = result.toRequestState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, RequestState<bool>>(
  (ref) => LoginNotifier(ref.watch(authUsecaseProvider)),
);

final signUpProvider =
    StateNotifierProvider.autoDispose<SignUpNotifier, RequestState<void>>(
  (ref) => SignUpNotifier(ref.watch(authUsecaseProvider)),
);

final forgotPasswordProvider = StateNotifierProvider.autoDispose<
        ForgotPasswordNotifier, RequestState<void>>(
    (ref) => ForgotPasswordNotifier(ref.watch(authUsecaseProvider)));

final profileSetupProvider =
    StateNotifierProvider.autoDispose<ProfileSetupNotifier, RequestState<void>>(
        (ref) => ProfileSetupNotifier(ref.watch(authUsecaseProvider)));

final changePasswordProvider = StateNotifierProvider.autoDispose<
        ChangePasswordNotifier, RequestState<void>>(
    (ref) => ChangePasswordNotifier(ref.watch(authUsecaseProvider)));

/// The signed-in user's devices. Errors carry the failure message.
final accountSessionsProvider =
    FutureProvider.autoDispose<List<AccountSession>>((ref) async {
  final result = await ref.watch(authUsecaseProvider).listSessions();
  return switch (result) {
    ResourceSuccess<List<AccountSession>>(:final data) => data,
    ResourceError<List<AccountSession>>(:final failure) =>
      throw failure.message,
    ResourceLoading<List<AccountSession>>() => const <AccountSession>[],
  };
});

final sessionActionsProvider = StateNotifierProvider.autoDispose<
        SessionActionsNotifier, RequestState<void>>(
    (ref) => SessionActionsNotifier(
          ref.watch(authUsecaseProvider),
          onChanged: () => ref.invalidate(accountSessionsProvider),
        ));

final editProfileProvider =
    StateNotifierProvider.autoDispose<EditProfileNotifier, RequestState<void>>(
        (ref) => EditProfileNotifier(ref.watch(authUsecaseProvider)));

final profileAvatarProvider =
    StateNotifierProvider.autoDispose<ProfileAvatarNotifier, File?>(
  (ref) => ProfileAvatarNotifier(ref.watch(authUsecaseProvider).pickAvatar),
);

final profileCoverProvider =
    StateNotifierProvider.autoDispose<ProfileAvatarNotifier, File?>(
  (ref) => ProfileAvatarNotifier(ref.watch(authUsecaseProvider).pickCover),
);

final usernameAvailabilityProvider = StateNotifierProvider.autoDispose<
        UsernameAvailabilityNotifier, RequestState<bool>>(
    (ref) => UsernameAvailabilityNotifier(ref.watch(authUsecaseProvider)));

/// The signed-in user's profile row (`null` when it can't be loaded).
final currentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final result = await ref.watch(authUsecaseProvider).getUser();
  return result.dataOrNull;
});

final signOutProvider =
    StateNotifierProvider.autoDispose<SignOutNotifier, RequestState<void>>(
  (ref) => SignOutNotifier(ref.watch(authUsecaseProvider)),
);

/// Another artist's profile row, by user id.
final userProfileProvider =
    FutureProvider.autoDispose.family<UserModel?, String>((ref, id) async {
  final result = await ref.watch(authUsecaseProvider).getUserById(id);
  return result.dataOrNull;
});

/// Name / username entered at sign-up, used to prefill profile setup.
final signUpPrefillProvider = FutureProvider.autoDispose<SignUpPrefill?>((
  ref,
) async {
  final result = await ref.watch(authUsecaseProvider).getSignUpPrefill();
  return result.dataOrNull;
});
