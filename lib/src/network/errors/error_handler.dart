import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../codes/postgres_error_codes.dart';
import '../codes/status_codes.dart';
import '../failures/failure.dart';

/// Converts anything thrown by the SDKs into a typed [Failure].
///
/// Usually reached through `Failure.fromException` / `runTask`.
abstract final class AppErrorHandler {
  AppErrorHandler._();

  /// Best-effort human-readable text for any thrown object.
  static String format(Object? error) {
    if (error == null) return 'An unexpected error occurred';
    if (error is String) return error;
    if (error is Failure) return error.message;

    try {
      final dynamic dynamicError = error;
      if (dynamicError.message is String) {
        return dynamicError.message as String;
      }
    } catch (_) {
      // Not every thrown object exposes `message`; fall through to toString().
    }

    return error.toString();
  }

  static Failure toFailure(Object error, [StackTrace? stackTrace]) {
    return switch (error) {
      final Failure f => f,
      final PostgrestException e => _fromPostgrest(e),
      final AuthException e => _fromAuth(e),
      final StorageException e => _fromStorage(e),
      final FunctionException e => _fromFunction(e),
      final TimeoutException e => TimeoutFailure(
          'The request timed out. Please try again.',
          error: e,
        ),
      final SocketException e => NetworkFailure(
          'No internet connection. Please check your connection and try again.',
          error: e,
        ),
      final HttpException e => NetworkFailure(format(e), error: e),
      _ => _fromGeneric(error),
    };
  }

  static Failure _fromGeneric(Object error) {
    final text = error.toString();
    if (error is Exception &&
        (text.contains('SocketException') ||
            text.contains('ClientException') ||
            text.contains('Network'))) {
      return NetworkFailure(
        'No internet connection. Please check your connection and try again.',
        error: error,
      );
    }
    return UnknownFailure(format(error), error: error);
  }

  // ── PostgREST / Postgres ──────────────────────────────────────────────────

  static Failure _fromPostgrest(PostgrestException e) {
    final code = e.code;
    final status = StatusCode.tryParse(code) ?? _statusFromCode(code);
    final message = PostgresErrorCode.messageFor(code) ??
        PostgrestErrorCode.messageFor(code) ??
        (e.message.isNotEmpty ? e.message : StatusCode.messageFor(status));

    switch (code) {
      case PostgresErrorCode.uniqueViolation:
        return ConflictFailure(message,
            error: e, code: code, statusCode: StatusCode.conflict);
      case PostgresErrorCode.notNullViolation:
      case PostgresErrorCode.foreignKeyViolation:
      case PostgresErrorCode.checkViolation:
      case PostgresErrorCode.invalidTextRepresentation:
      case PostgresErrorCode.numericValueOutOfRange:
      case PostgresErrorCode.stringDataRightTruncation:
      case PostgresErrorCode.invalidDatetimeFormat:
        return ValidationFailure(message,
            error: e, code: code, statusCode: StatusCode.badRequest);
      case PostgresErrorCode.insufficientPrivilege:
        return PermissionFailure(message,
            error: e, code: code, statusCode: StatusCode.forbidden);
      case PostgrestErrorCode.noRowsOrMultiple:
        return NotFoundFailure(message,
            error: e, code: code, statusCode: StatusCode.notFound);
      case PostgrestErrorCode.jwtExpired:
      case PostgrestErrorCode.anonymousDisabled:
        return AuthFailure(message,
            error: e, code: code, statusCode: StatusCode.unauthorized);
      case PostgresErrorCode.queryCanceled:
        return TimeoutFailure(message,
            error: e, statusCode: StatusCode.requestTimeout);
      case PostgresErrorCode.undefinedTable:
        return NotFoundFailure(message,
            error: e, code: code, statusCode: StatusCode.notFound);
    }

    return ServerFailure(message, error: e, code: code, statusCode: status);
  }

  /// Rough HTTP status for SQLSTATE classes without a dedicated mapping.
  static int? _statusFromCode(String? code) {
    if (code == null || code.length < 2) return null;
    return switch (code.substring(0, 2)) {
      '08' || '53' || '54' => StatusCode.serviceUnavailable,
      '42' => StatusCode.badRequest,
      _ => StatusCode.internalServerError,
    };
  }

  // ── Auth (GoTrue) ─────────────────────────────────────────────────────────

  static Failure _fromAuth(AuthException e) {
    final status = StatusCode.tryParse(e.statusCode);
    final code = e.code;
    final message = switch (code) {
      'invalid_credentials' => 'Incorrect email or password.',
      'email_not_confirmed' => 'Please verify your email before signing in.',
      'user_already_exists' ||
      'email_exists' =>
        'An account with this email already exists.',
      'weak_password' => 'That password is too weak.',
      'user_not_found' => 'No account found with that email.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        'Too many attempts. Please wait a moment and try again.',
      'session_expired' ||
      'refresh_token_not_found' =>
        'Your session has expired. Please sign in again.',
      _ => e.message,
    };

    if (status == StatusCode.tooManyRequests ||
        (code?.startsWith('over_') ?? false)) {
      return RateLimitFailure(message,
          error: e, code: code, statusCode: StatusCode.tooManyRequests);
    }
    if (code == 'user_already_exists' || code == 'email_exists') {
      return ConflictFailure(message,
          error: e, code: code, statusCode: StatusCode.conflict);
    }
    if (code == 'weak_password') {
      return ValidationFailure(message,
          error: e, code: code, statusCode: StatusCode.unprocessableEntity);
    }
    return AuthFailure(message, error: e, code: code, statusCode: status);
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  static Failure _fromStorage(StorageException e) {
    final status = StatusCode.tryParse(e.statusCode);
    final message = switch (status) {
      StatusCode.payloadTooLarge => StatusCode.messageFor(status),
      StatusCode.unsupportedMediaType => StatusCode.messageFor(status),
      StatusCode.unauthorized || StatusCode.forbidden =>
        "You don't have permission to upload here.",
      StatusCode.notFound => "We couldn't find that file.",
      StatusCode.conflict => 'A file with that name already exists.',
      _ => e.message,
    };
    return StorageFailure(message, error: e, statusCode: status);
  }

  // ── Edge Functions ────────────────────────────────────────────────────────

  static Failure _fromFunction(FunctionException e) {
    final status = e.status;
    final message = StatusCode.messageFor(status);
    return switch (status) {
      StatusCode.unauthorized =>
        AuthFailure(message, error: e, statusCode: status),
      StatusCode.forbidden =>
        PermissionFailure(message, error: e, statusCode: status),
      StatusCode.notFound =>
        NotFoundFailure(message, error: e, statusCode: status),
      StatusCode.tooManyRequests =>
        RateLimitFailure(message, error: e, statusCode: status),
      StatusCode.badRequest || StatusCode.unprocessableEntity =>
        ValidationFailure(message, error: e, statusCode: status),
      _ => ServerFailure(message, error: e, statusCode: status),
    };
  }
}
