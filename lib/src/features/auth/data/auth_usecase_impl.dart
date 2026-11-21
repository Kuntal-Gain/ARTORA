import 'dart:io';

import 'package:artora/src/features/auth/data/auth_usecase.dart';
import 'package:artora/src/features/auth/model/account_session.dart';
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
        await getUserById(data['id'] as String),
      ResourceError<Map<String, dynamic>>(:final failure) =>
        Resource<UserModel>.error(failure),
      ResourceLoading<Map<String, dynamic>>() =>
        const Resource<UserModel>.loading(),
    };
  }

  @override
  Future<Resource<UserModel>> getUserById(String id) async {
    // Profile row + follow counts in one call (supabase/get_user_by_id.sql).
    final res = await _db.rpc<Map<String, dynamic>?>(
      SupabaseRpc.getUserById,
      params: {'p_id': id},
    );
    return switch (res) {
      ResourceSuccess<Map<String, dynamic>?>(:final data) when data != null =>
        Resource.success(UserModel.fromJson(data)),
      // No row: hasProfile() relies on this to send new accounts to setup.
      ResourceSuccess<Map<String, dynamic>?>() =>
        const Resource<UserModel>.error(
          NotFoundFailure('Profile not found.', statusCode: 404),
        ),
      ResourceError<Map<String, dynamic>?>(:final failure) =>
        Resource<UserModel>.error(failure),
      ResourceLoading<Map<String, dynamic>?>() =>
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
  Future<Resource<File?>> pickAvatar() => _pickImage(1024, 1024);

  @override
  Future<Resource<File?>> pickCover() => _pickImage(1920, 1080);

  Future<Resource<File?>> _pickImage(double maxWidth, double maxHeight) async {
    final picked = await MediaService.instance.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
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

    final upload = await _uploadImage(
      SupabaseBuckets.avatars,
      SupabaseBuckets.avatarPath,
      id,
      params.avatar,
    );
    if (upload case ResourceError<String?>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final avatarPath = upload.dataOrNull;

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

  /// Uploads [file] to [bucket] at [pathFor] and returns the storage path;
  /// success with `null` when there is no new file.
  Future<Resource<String?>> _uploadImage(
    String bucket,
    String Function(String userId, {String ext}) pathFor,
    String userId,
    File? file, {
    UploadProgress? onProgress,
  }) async {
    if (file == null) return const Resource<String?>.success(null);
    final ext = _extensionOf(file.path);
    final path = pathFor(userId, ext: ext);
    final upload = await _storage.uploadFile(
      bucket: bucket,
      path: path,
      file: file,
      contentType: _mimeByExtension[ext],
      onProgress: onProgress,
    );
    return upload.fold(
      (failure) => Resource<String?>.error(failure),
      (_) => Resource<String?>.success(path),
    );
  }

  @override
  Future<Resource<void>> updateProfile(
    ProfileSetupParams params, {
    File? cover,
    UploadProgress? onProgress,
  }) async {
    final authUser = await _authUser();
    if (authUser case ResourceError<Map<String, dynamic>>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final id = authUser.dataOrNull!['id'] as String;

    // One 0–1 bar across both files, weighted by size.
    final avatarBytes = await params.avatar?.length() ?? 0;
    final coverBytes = await cover?.length() ?? 0;
    final totalBytes = avatarBytes + coverBytes;
    UploadProgress? part(int offset, int bytes) =>
        onProgress == null || totalBytes == 0
            ? null
            : (p) => onProgress((offset + p * bytes) / totalBytes);

    final upload = await _uploadImage(
      SupabaseBuckets.avatars,
      SupabaseBuckets.avatarPath,
      id,
      params.avatar,
      onProgress: part(0, avatarBytes),
    );
    if (upload case ResourceError<String?>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final avatarPath = upload.dataOrNull;

    final coverUpload = await _uploadImage(
      SupabaseBuckets.banners,
      SupabaseBuckets.coverPath,
      id,
      cover,
      onProgress: part(avatarBytes, coverBytes),
    );
    if (coverUpload case ResourceError<String?>(:final failure)) {
      return Resource<void>.error(failure);
    }
    final coverPath = coverUpload.dataOrNull;

    // Patch only the edited columns so website and socials stay as-is.
    final res = await _db.patch(
      SupabaseTables.profiles,
      {
        'display_name': params.displayName,
        'username': params.username,
        'bio': params.bio,
        'specialties': params.specialties,
        if (avatarPath != null) 'avatar_path': avatarPath,
        if (coverPath != null) 'cover_path': coverPath,
      },
      eq: {'id': id},
    );
    return res.map<void>((_) {});
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
  Future<Resource<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final verified = await _auth.verifyPassword(currentPassword);
    final rejected = verified.fold<Failure?>(
      (failure) => failure,
      (matches) => matches
          ? null
          : const ValidationFailure('Current password is incorrect.'),
    );
    if (rejected != null) return Resource<void>.error(rejected);

    final updated = await _auth.updatePassword(newPassword);
    final failure = updated.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return Resource<void>.error(failure);

    // The password is already changed; signing the others out is a safety
    // extra, so a failure here must not turn the change into an error.
    await _auth.signOutOtherDevices();
    return const Resource<void>.success(null);
  }

  @override
  Future<Resource<List<AccountSession>>> listSessions() async {
    final res = await _auth.listSessions();
    return Resource.fromEither(
      res.map((rows) => rows.map(AccountSession.fromJson).toList()),
    );
  }

  @override
  Future<Resource<void>> revokeSession(String sessionId) async =>
      Resource.fromEither(await _auth.revokeSession(sessionId));

  @override
  Future<Resource<void>> signOutOtherDevices() async =>
      Resource.fromEither(await _auth.signOutOtherDevices());

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
