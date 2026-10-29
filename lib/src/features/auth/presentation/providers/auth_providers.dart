import 'dart:async';
import 'dart:io';

import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/data/auth_usecase_impl.dart';
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

/// Holds the photo chosen on the profile setup screen.
class ProfileAvatarNotifier extends StateNotifier<File?> {
  ProfileAvatarNotifier(this._usecase) : super(null);

  final AuthUsecase _usecase;

  /// Returns the failure to show, or `null` when a photo was chosen or the
  /// picker was dismissed (the previous photo is kept in that case).
  Future<Failure?> pick() async {
    final result = await _usecase.pickAvatar();
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
  ForgotPasswordNotifier,
  RequestState<void>
>((ref) => ForgotPasswordNotifier(ref.watch(authUsecaseProvider)));

final profileSetupProvider = StateNotifierProvider.autoDispose<
  ProfileSetupNotifier,
  RequestState<void>
>((ref) => ProfileSetupNotifier(ref.watch(authUsecaseProvider)));

final profileAvatarProvider =
    StateNotifierProvider.autoDispose<ProfileAvatarNotifier, File?>(
      (ref) => ProfileAvatarNotifier(ref.watch(authUsecaseProvider)),
    );

final usernameAvailabilityProvider = StateNotifierProvider.autoDispose<
  UsernameAvailabilityNotifier,
  RequestState<bool>
>((ref) => UsernameAvailabilityNotifier(ref.watch(authUsecaseProvider)));

/// Name / username entered at sign-up, used to prefill profile setup.
final signUpPrefillProvider = FutureProvider.autoDispose<SignUpPrefill?>((
  ref,
) async {
  final result = await ref.watch(authUsecaseProvider).getSignUpPrefill();
  return result.dataOrNull;
});
