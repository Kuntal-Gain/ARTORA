import 'package:equatable/equatable.dart';

import '../errors/error_handler.dart';

/// Domain-level failure hierarchy. Prefer exhaustive `switch` over `is` checks.
///
/// Optional [code] carries the backend error code (SQLSTATE, `PGRST…`, GoTrue
/// code) and [statusCode] the HTTP status, so UI and logs can branch on them.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.error, this.code, this.statusCode});

  final String message;
  final Object? error;
  final String? code;
  final int? statusCode;

  /// Maps thrown objects into a typed [Failure] for railway-style APIs.
  factory Failure.fromException(Object error, [StackTrace? stackTrace]) =>
      AppErrorHandler.toFailure(error, stackTrace);

  @override
  List<Object?> get props => [message, error, code, statusCode];

  @override
  String toString() => message;
}

/// 5xx / unexpected backend response.
final class ServerFailure extends Failure {
  const ServerFailure(super.message,
      {super.error, super.code, super.statusCode});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.error});
}

/// No connectivity or transport-level failure.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.error});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.error, super.statusCode});
}

/// Sign-in / session problems (invalid credentials, expired JWT, unverified email…).
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.error, super.code, super.statusCode});
}

/// Authenticated but not allowed (RLS denial, insufficient privilege).
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message,
      {super.error, super.code, super.statusCode});
}

/// Row / object / route not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message,
      {super.error, super.code, super.statusCode});
}

/// Duplicate or conflicting data (unique violation, 409).
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message,
      {super.error, super.code, super.statusCode});
}

/// Invalid input (not-null, check, bad format, 400 / 422).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message,
      {super.error, super.code, super.statusCode});
}

/// Too many requests.
final class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message,
      {super.error, super.code, super.statusCode});
}

/// Supabase Storage failure (upload too large, bucket missing…).
final class StorageFailure extends Failure {
  const StorageFailure(super.message,
      {super.error, super.code, super.statusCode});
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.error});
}
