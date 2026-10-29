import 'dart:io';

import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/network/client/sb_client.dart';
import 'package:artora/src/network/constants/supabase_buckets.dart';
import 'package:artora/src/network/constants/supabase_tables.dart';
import 'package:artora/src/network/failures/failure.dart';
import 'package:artora/src/network/resource/resource.dart';
import 'package:artora/src/services/auth_service.dart';
import 'package:artora/src/services/media_service.dart';
import 'package:artora/src/services/supabase_storage_service.dart';
import 'package:image_picker/image_picker.dart';

class AuthUsecaseImpl implements AuthUsecase {
  static const Map<String, String> _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  AuthService get _auth => AuthService.instance;
  SBClient get _db => SBClient.instance;
  SupabaseStorageService get _storage => SupabaseStorageService.instance;

  /// The signed-in auth user, or an [AuthFailure] when there is no session.
  Future<Resource<Map<String, dynamic>>> _authUser() async {
    final current = await _auth.getCurrentUser();
    return current.fold(
      (failure) => Resource<Map<String, dynamic>>.error(failure),
      (user) => user == null
          ? const Resource<Map<String, dynamic>>.error(
              AuthFailure('You are not signed in.', statusCode: 401),
            )
          : Resource.success(user),
    );
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  }

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
    final authUser = await _authUser();
    return switch (authUser) {
      ResourceSuccess<Map<String, dynamic>>(:final data) =>
        (await _db.getOne(
          SupabaseTables.profiles,
          eq: {SupabaseColumns.id: data['id']},
        )).map(UserModel.fromJson),
      ResourceError<Map<String, dynamic>>(:final failure) =>
        Resource<UserModel>.error(failure),
      ResourceLoading<Map<String, dynamic>>() =>
        const Resource<UserModel>.loading(),
    };
  }

  @override
  Future<Resource<bool>> hasProfile() async {
    final profile = await getUser();
    return switch (profile) {
      ResourceSuccess<UserModel>() => const Resource<bool>.success(true),
      ResourceError<UserModel>(:final failure) when failure is NotFoundFailure =>
        const Resource<bool>.success(false),
      ResourceError<UserModel>(:final failure) =>
        Resource<bool>.error(failure),
      ResourceLoading<UserModel>() => const Resource<bool>.loading(),
    };
  }

  @override
  Future<Resource<bool>> isSignedIn() async {
    final current = await _auth.getCurrentUser();
    return Resource.fromEither(current.map((user) => user != null));
  }

  @override
  Future<Resource<bool>> isUsernameAvailable(String username) {
    return _db.rpc<bool>(
      SupabaseRpc.isUsernameAvailable,
      params: {'username': username},
    );
  }

  @override
  Future<Resource<SignUpPrefill>> getSignUpPrefill() async {
    final current = await _auth.getCurrentUser();
    return Resource.fromEither(
      current.map(
        (user) => (
          name: user?['name'] as String?,
          username: user?['username'] as String?,
        ),
      ),
    );
  }

  @override
  Future<Resource<File?>> pickAvatar() async {
    final picked = await MediaService.instance.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    final failure = picked.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return Resource<File?>.error(failure);

    final file = picked.fold<File?>((_) => null, (f) => f);
    if (file == null) return const Resource<File?>.success(null);

    if (!_mimeByExtension.containsKey(_extensionOf(file.path))) {
      return const Resource<File?>.error(
        ValidationFailure('Use a JPG, PNG or WebP image.'),
      );
    }
    if (await file.length() > StorageLimits.maxAvatarBytes) {
      return const Resource<File?>.error(
        ValidationFailure('Photo must be under 2 MB.'),
      );
    }
    return Resource<File?>.success(file);
  }

  @override
  Future<Resource<void>> setupProfile(ProfileSetupParams params) async {
    final authUser = await _authUser();
    return switch (authUser) {
      ResourceSuccess<Map<String, dynamic>>(:final data) =>
        await _saveProfile(data, params),
      ResourceError<Map<String, dynamic>>(:final failure) =>
        Resource<void>.error(failure),
      ResourceLoading<Map<String, dynamic>>() => const Resource<void>.loading(),
    };
  }

  Future<Resource<void>> _saveProfile(
    Map<String, dynamic> authUser,
    ProfileSetupParams params,
  ) async {
    final id = authUser['id'] as String;

    String? avatarPath;
    final avatar = params.avatar;
    if (avatar != null) {
      final ext = _extensionOf(avatar.path);
      final path = SupabaseBuckets.avatarPath(id, ext: ext);
      final upload = await _storage.uploadFile(
        bucket: SupabaseBuckets.avatars,
        path: path,
        file: avatar,
        contentType: _mimeByExtension[ext],
      );
      final failure = upload.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) return Resource<void>.error(failure);
      avatarPath = path;
    }

    return createUser(
      UserModel(
        id: id,
        email: authUser['email'] as String?,
        username: params.username,
        displayName: params.displayName,
        bio: params.bio,
        avatarPath: avatarPath,
        specialties: params.specialties,
      ),
    );
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
