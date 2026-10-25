/// HTTP status codes used by Supabase (PostgREST, GoTrue, Storage, Edge Functions).
abstract final class StatusCode {
  StatusCode._();

  // 2xx — success
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;
  static const int partialContent = 206;

  // 3xx — redirection
  static const int notModified = 304;

  // 4xx — client errors
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int paymentRequired = 402;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int notAcceptable = 406;
  static const int requestTimeout = 408;
  static const int conflict = 409;
  static const int gone = 410;
  static const int payloadTooLarge = 413;
  static const int unsupportedMediaType = 415;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;

  // 5xx — server errors
  static const int internalServerError = 500;
  static const int notImplemented = 501;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;

  static bool isSuccess(int? code) => code != null && code >= 200 && code < 300;
  static bool isRedirect(int? code) => code != null && code >= 300 && code < 400;
  static bool isClientError(int? code) =>
      code != null && code >= 400 && code < 500;
  static bool isServerError(int? code) => code != null && code >= 500;

  /// Parses codes that some SDKs expose as strings (e.g. `StorageException`).
  static int? tryParse(String? code) => code == null ? null : int.tryParse(code);

  /// Default user-facing message for a status code.
  static String messageFor(int? code) => switch (code) {
        badRequest => 'The request was invalid. Please try again.',
        unauthorized => 'Your session has expired. Please sign in again.',
        forbidden => "You don't have permission to do that.",
        notFound => "We couldn't find what you were looking for.",
        requestTimeout || gatewayTimeout =>
          'The request timed out. Please try again.',
        conflict => 'This conflicts with existing data.',
        payloadTooLarge => 'That file is too large.',
        unsupportedMediaType => 'That file type is not supported.',
        unprocessableEntity => 'Some of the information provided is invalid.',
        tooManyRequests => 'Too many requests. Please slow down and retry.',
        final c? when isServerError(c) =>
          'Something went wrong on our side. Please try again later.',
        _ => 'Something went wrong. Please try again.',
      };
}
