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

class LoginNotifier extends StateNotifier<RequestState<void>> {
  LoginNotifier(this._usecase) : super(const RequestInitial());

  final AuthUsecase _usecase;

  Future<void> submit(LoginParams params) async {
    state = const RequestLoading();
    final result = await _usecase.signIn(
      email: params.email,
      password: params.password,
    );
    if (!mounted) return;
    state = result.toRequestState();
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

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, RequestState<void>>(
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
