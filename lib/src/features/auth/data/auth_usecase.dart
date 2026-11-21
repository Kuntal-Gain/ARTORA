import 'dart:io';

import 'package:artora/src/features/auth/model/account_session.dart';
import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/imports/core_imports.dart';
import 'package:artora/src/services/supabase_storage_service.dart';

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

  /// Any artist's public profile row.
  Future<Resource<UserModel>> getUserById(String id);
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

  /// Changes the password after checking [currentPassword], then signs every
  /// other device out. Needs supabase/account.sql.
  Future<Resource<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// The signed-in user's devices, most recently used first.
  Future<Resource<List<AccountSession>>> listSessions();

  /// Signs one other device out (not the current one).
  Future<Resource<void>> revokeSession(String sessionId);

  /// Signs every device out except this one.
  Future<Resource<void>> signOutOtherDevices();

  /// Lets the user choose a wide cover photo; same contract as [pickAvatar].
  Future<Resource<File?>> pickCover();

  /// Updates the signed-in user's profile; a `null` avatar or [cover] keeps
  /// the current one. [onProgress] reports the photo uploads (0–1).
  Future<Resource<void>> updateProfile(
    ProfileSetupParams params, {
    File? cover,
    UploadProgress? onProgress,
  });
}
