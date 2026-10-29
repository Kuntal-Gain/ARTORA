import 'dart:io';

import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/imports/core_imports.dart';

typedef ProfileSetupParams = ({
  String displayName,
  String username,
  String? bio,
  List<String> specialties,
  File? avatar,
});

/// Name and username captured at sign-up (kept in the auth metadata).
typedef SignUpPrefill = ({String? name, String? username});

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

  /// Whether the signed-in user already has a row in `profiles`.
  Future<Resource<bool>> hasProfile();
  Future<Resource<bool>> isUsernameAvailable(String username);
  Future<Resource<SignUpPrefill>> getSignUpPrefill();

  /// Lets the user choose a photo from the gallery. Success with `null` means
  /// the picker was dismissed.
  Future<Resource<File?>> pickAvatar();

  /// Uploads the avatar (if any) and creates the signed-in user's profile.
  Future<Resource<void>> setupProfile(ProfileSetupParams params);
}
