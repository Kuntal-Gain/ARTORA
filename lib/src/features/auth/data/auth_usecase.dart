import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/imports/core_imports.dart';

abstract class AuthUsecase {
  Future<Resource<void>> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  });
  Future<Resource<void>> signIn({required String email, required String password});
  Future<Resource<void>> signOut();
  Future<Resource<void>> forgotPassword({required String email});
  Future<Resource<bool>> isSignedIn();
  Future<Resource<UserModel>> getUser();
  Future<Resource<void>> createUser(UserModel user);
}
