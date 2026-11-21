import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../utils/utils.dart';

/// Upload progress from 0 to 1.
typedef UploadProgress = void Function(double progress);

/// Uploads to Supabase Storage. Paths follow `SupabaseBuckets` so RLS can match
/// on the first segment (`<userId>/…`).
class SupabaseStorageService {
  SupabaseStorageService._();
  static final instance = SupabaseStorageService._();

  SupabaseClient get _client => AppConfig.supabase;

  /// Public URL for a stored object; `null`/empty [path] gives `null`.
  /// Assumes the bucket is public.
  String? publicUrl(String bucket, String? path) => path == null || path.isEmpty
      ? null
      : _client.storage.from(bucket).getPublicUrl(path);

  /// Uploads [file] to [bucket]/[path] and returns [path].
  ///
  /// With [onProgress] the file is streamed to the Storage REST API so bytes
  /// sent can be reported; the SDK's upload has no progress callback.
  FutureEither<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
    bool upsert = true,
    UploadProgress? onProgress,
  }) {
    return runTask(
      () async {
        if (onProgress != null) {
          await _uploadWithProgress(
            bucket: bucket,
            path: path,
            file: file,
            contentType: contentType,
            upsert: upsert,
            onProgress: onProgress,
          );
        } else {
          await _client.storage.from(bucket).upload(
                path,
                file,
                fileOptions: FileOptions(
                  upsert: upsert,
                  contentType: contentType,
                ),
              );
        }
        return path;
      },
      operation: 'storage.upload',
      category: LogCategory.database,
      context: {'bucket': bucket, 'path': path},
      requiresNetwork: true,
    );
  }

  // Progress = bytes the server has acknowledged, give or take one send
  // buffer: the connection's OS send buffer is shrunk to [_sendBufferBytes]
  // and TCP keeps unacknowledged bytes in that buffer, so `flush()` only
  // completes once the server has received all but the last ~buffer's worth.
  Future<void> _uploadWithProgress({
    required String bucket,
    required String path,
    required File file,
    required String? contentType,
    required bool upsert,
    required UploadProgress onProgress,
  }) async {
    final total = await file.length();
    final anonKey = AppConfig.supabaseAnonKey;
    final token = _client.auth.currentSession?.accessToken ?? anonKey;
    final uri = Uri.parse(
      '${AppConfig.supabaseUrl}/storage/v1/object/$bucket/$path',
    );

    final http = HttpClient()..connectionFactory = _smallBufferConnection;
    try {
      final request = await http.postUrl(uri);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
        ..set('apikey', anonKey)
        ..set('x-upsert', '$upsert')
        ..set(HttpHeaders.cacheControlHeader, 'max-age=3600')
        ..contentLength = total;
      if (contentType != null) {
        request.headers.contentType = ContentType.parse(contentType);
      }

      // Small chunks, each flushed before the next, so progress moves in step
      // with what the server acknowledges. 100% waits for its response.
      var sent = 0;
      onProgress(0);
      await for (final chunk in file.openRead()) {
        for (var i = 0; i < chunk.length; i += _chunkBytes) {
          final end = min(i + _chunkBytes, chunk.length);
          request.add(chunk.sublist(i, end));
          await request.flush();
          sent += end - i;
          onProgress(min(sent / total, _maxBeforeResponse));
        }
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 300) {
        throw StorageException(
          _errorMessage(body) ?? 'Upload failed (${response.statusCode}).',
          statusCode: '${response.statusCode}',
        );
      }
      onProgress(1);
    } finally {
      http.close();
    }
  }

  /// OS send buffer for upload connections. TCP holds unacknowledged bytes
  /// here, so a small buffer makes "written" track "received by the server".
  static const int _sendBufferBytes = 32 * 1024;

  /// Bytes written per flush.
  static const int _chunkBytes = 16 * 1024;

  /// Never show 100% before the server has answered.
  static const double _maxBeforeResponse = 0.99;

  /// `SO_SNDBUF`: 7 on Linux/Android, 0x1001 on Apple platforms and Windows.
  static int get _soSndBuf =>
      Platform.isAndroid || Platform.isLinux ? 7 : 0x1001;

  /// Opens the socket itself so the send buffer can be shrunk before TLS is
  /// layered on top. With a custom factory, HttpClient expects an already
  /// secured socket for https.
  static Future<ConnectionTask<Socket>> _smallBufferConnection(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    final task = await Socket.startConnect(uri.host, uri.port);
    Future<Socket> connect() async {
      final socket = await task.socket;
      try {
        socket.setRawOption(
          RawSocketOption.fromInt(
            RawSocketOption.levelSocket,
            _soSndBuf,
            _sendBufferBytes,
          ),
        );
      } on SocketException catch (e) {
        // Upload still works, progress just runs ahead like before.
        AppLogger.warning('Could not shrink upload send buffer', error: e);
      }
      return uri.scheme == 'https'
          ? SecureSocket.secure(socket, host: uri.host)
          : socket;
    }

    return ConnectionTask.fromSocket(connect(), task.cancel);
  }

  static String? _errorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json is Map ? json['message'] as String? : null;
    } on FormatException {
      return body.isEmpty ? null : body;
    }
  }
}
