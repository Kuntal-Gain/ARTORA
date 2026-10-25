import 'package:artora/src/imports/core_imports.dart';

abstract class AuthUsecase {

  Future<Resource<void>> signUp({required String email, required String password});
  Future<Resource<void>> signIn({required String email, required String password});
}
