import 'package:artora/src/imports/imports.dart';

typedef LoginParams = ({String email, String password});
typedef SignUpParams = ({
  String name,
  String username,
  String email,
  String password,
});

/// Maps a service result onto [RequestState] so screens never see `Either`.
RequestState<void> _toState<T>(Either<Failure, T> result) =>
    result.fold<RequestState<void>>(
      RequestFailure<void>.new,
      (_) => const RequestSuccess<void>(null),
    );

class LoginNotifier extends StateNotifier<RequestState<void>> {
  LoginNotifier() : super(const RequestInitial());

  Future<void> submit(LoginParams params) async {
    state = const RequestLoading();
    final result = await AuthService.instance.login(
      email: params.email,
      password: params.password,
    );
    if (!mounted) return;
    state = _toState(result);
  }
}

class SignUpNotifier extends StateNotifier<RequestState<void>> {
  SignUpNotifier() : super(const RequestInitial());

  Future<void> submit(SignUpParams params) async {
    state = const RequestLoading();
    final result = await AuthService.instance.signUp(
      name: params.name,
      username: params.username,
      email: params.email,
      password: params.password,
    );
    if (!mounted) return;
    state = _toState(result);
  }
}

class ForgotPasswordNotifier extends StateNotifier<RequestState<void>> {
  ForgotPasswordNotifier() : super(const RequestInitial());

  Future<void> submit(String email) async {
    state = const RequestLoading();
    final result = await AuthService.instance.forgotPassword(email: email);
    if (!mounted) return;
    state = _toState(result);
  }
}

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, RequestState<void>>(
      (ref) => LoginNotifier(),
    );

final signUpProvider =
    StateNotifierProvider.autoDispose<SignUpNotifier, RequestState<void>>(
      (ref) => SignUpNotifier(),
    );

final forgotPasswordProvider = StateNotifierProvider.autoDispose<
  ForgotPasswordNotifier,
  RequestState<void>
>((ref) => ForgotPasswordNotifier());
