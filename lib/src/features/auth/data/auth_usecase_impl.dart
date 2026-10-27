import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/network/client/sb_client.dart';
import 'package:artora/src/network/constants/supabase_tables.dart';
import 'package:artora/src/network/failures/failure.dart';
import 'package:artora/src/network/resource/resource.dart';
import 'package:artora/src/services/auth_service.dart';

class AuthUsecaseImpl implements AuthUsecase {
  AuthService get _auth => AuthService.instance;
  SBClient get _db => SBClient.instance;

  @override
  Future<Resource<void>> createUser(UserModel user) async {
    final values = user.toJson()
      ..removeWhere((key, value) =>
          value == null &&
          (key == SupabaseColumns.createdAt ||
              key == SupabaseColumns.updatedAt));
    final res = await _db.put(SupabaseTables.profiles, values);
    return res.map<void>((_) {});
  }

  @override
  Future<Resource<UserModel>> getUser() async {
    final current = await _auth.getCurrentUser();
    final id = current.fold<String?>(
      (_) => null,
      (user) => user?['id'] as String?,
    );
    if (id == null) {
      return current.fold(
        (failure) => Resource.error(failure),
        (_) => const Resource.error(
          AuthFailure('You are not signed in.', statusCode: 401),
        ),
      );
    }

    final res = await _db.getOne(
      SupabaseTables.profiles,
      eq: {SupabaseColumns.id: id},
    );
    return res.map(UserModel.fromJson);
  }

  @override
  Future<Resource<bool>> isSignedIn() async {
    final current = await _auth.getCurrentUser();
    return Resource.fromEither(current.map((user) => user != null));
  }

  @override
  Future<Resource<void>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _auth.login(email: email, password: password);
    return Resource.fromEither(res.map<void>((_) {}));
  }

  @override
  Future<Resource<void>> signOut() async {
    final res = await _auth.logout();
    return Resource.fromEither(res);
  }

  @override
  Future<Resource<void>> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _auth.signUp(
      name: name,
      username: username,
      email: email,
      password: password,
    );
    return Resource.fromEither(res.map<void>((_) {}));
  }

  @override
  Future<Resource<void>> forgotPassword({required String email}) async {
    final res = await _auth.forgotPassword(email: email);
    return Resource.fromEither(res);
  }
}
