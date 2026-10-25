/// PostgreSQL SQLSTATE codes surfaced through `PostgrestException.code`.
///
/// Full list: https://www.postgresql.org/docs/current/errcodes-appendix.html
abstract final class PostgresErrorCode {
  PostgresErrorCode._();

  // Class 08 — connection exception
  static const String connectionException = '08000';
  static const String connectionFailure = '08006';

  // Class 22 — data exception
  static const String invalidTextRepresentation = '22P02';
  static const String numericValueOutOfRange = '22003';
  static const String stringDataRightTruncation = '22001';
  static const String invalidDatetimeFormat = '22007';

  // Class 23 — integrity constraint violation
  static const String notNullViolation = '23502';
  static const String foreignKeyViolation = '23503';
  static const String uniqueViolation = '23505';
  static const String checkViolation = '23514';

  // Class 40 — transaction rollback
  static const String serializationFailure = '40001';
  static const String deadlockDetected = '40P01';

  // Class 42 — syntax error / access rule violation
  static const String syntaxError = '42601';
  static const String insufficientPrivilege = '42501';
  static const String undefinedColumn = '42703';
  static const String undefinedFunction = '42883';
  static const String undefinedTable = '42P01';

  // Class 53 / 54 / 57 — resources & operator intervention
  static const String insufficientResources = '53000';
  static const String tooManyConnections = '53300';
  static const String programLimitExceeded = '54000';
  static const String queryCanceled = '57014';

  // Class P0 — PL/pgSQL (`raise exception` in your own functions / triggers)
  static const String raiseException = 'P0001';

  /// Default user-facing message for a SQLSTATE code, or `null` if unmapped.
  static String? messageFor(String? code) => switch (code) {
        uniqueViolation => 'That already exists.',
        foreignKeyViolation => 'This refers to something that no longer exists.',
        notNullViolation => 'A required field is missing.',
        checkViolation || invalidTextRepresentation ||
        numericValueOutOfRange || invalidDatetimeFormat =>
          'Some of the information provided is invalid.',
        stringDataRightTruncation => 'One of the values is too long.',
        insufficientPrivilege => "You don't have permission to do that.",
        serializationFailure || deadlockDetected =>
          'The server is busy. Please try again.',
        connectionException || connectionFailure || tooManyConnections ||
        insufficientResources =>
          'The service is temporarily unavailable. Please try again.',
        queryCanceled => 'The request took too long. Please try again.',
        _ => null,
      };
}

/// PostgREST-specific error codes (`PGRST…`) surfaced via `PostgrestException.code`.
///
/// Full list: https://postgrest.org/en/stable/references/errors.html
abstract final class PostgrestErrorCode {
  PostgrestErrorCode._();

  /// `.single()` / `.maybeSingle()` matched zero (or more than one) rows.
  static const String noRowsOrMultiple = 'PGRST116';

  /// JWT has expired.
  static const String jwtExpired = 'PGRST301';

  /// Anonymous access is disabled / JWT missing required claim.
  static const String anonymousDisabled = 'PGRST302';

  /// Requested relationship / column not found in the schema cache.
  static const String columnNotFound = 'PGRST204';
  static const String relationshipNotFound = 'PGRST200';
  static const String schemaCacheMiss = 'PGRST205';

  /// Requested range is not satisfiable.
  static const String invalidRange = 'PGRST103';

  static String? messageFor(String? code) => switch (code) {
        noRowsOrMultiple => "We couldn't find what you were looking for.",
        jwtExpired || anonymousDisabled =>
          'Your session has expired. Please sign in again.',
        _ => null,
      };
}
