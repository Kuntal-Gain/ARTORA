import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../utils/utils.dart';

/// Uploads to Supabase Storage. Paths follow `SupabaseBuckets` so RLS can match
/// on the first segment (`<userId>/…`).
class SupabaseStorageService {
  SupabaseStorageService._();
  static final instance = SupabaseStorageService._();

  SupabaseClient get _client => AppConfig.supabase;

  /// Uploads [file] to [bucket]/[path] and returns [path].
  FutureEither<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
    bool upsert = true,
  }) {
    return runTask(
      () async {
        await _client.storage
            .from(bucket)
            .upload(
              path,
              file,
              fileOptions: FileOptions(
                upsert: upsert,
                contentType: contentType,
              ),
            );
        return path;
      },
      operation: 'storage.upload',
      category: LogCategory.database,
      context: {'bucket': bucket, 'path': path},
      requiresNetwork: true,
    );
  }
}
