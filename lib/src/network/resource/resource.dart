import 'package:fpdart/fpdart.dart';

import '../../utils/async_state.dart';
import '../codes/status_codes.dart';
import '../failures/failure.dart';

/// Response envelope returned from repositories / services.
///
/// ```dart
/// final Resource<List<Artwork>> res = await repo.feed();
/// switch (res) {
///   ResourceLoading() => const AppLoading(),
///   ResourceSuccess(:final data) => FeedList(data),
///   ResourceError(:final failure) => AppErrorWidget(message: failure.message),
/// }
/// ```
sealed class Resource<T> {
  const Resource();

  const factory Resource.loading() = ResourceLoading<T>;
  const factory Resource.success(
    T data, {
    String? message,
    int? statusCode,
    Map<String, Object?> meta,
  }) = ResourceSuccess<T>;
  const factory Resource.error(Failure failure) = ResourceError<T>;

  /// Runs [action], capturing any thrown error as a [ResourceError].
  static Future<Resource<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Resource.success(await action());
    } catch (error, stackTrace) {
      return Resource.error(Failure.fromException(error, stackTrace));
    }
  }

  /// Wraps an `Either<Failure, T>` (the `FutureEither` result type).
  factory Resource.fromEither(Either<Failure, T> either) => either.fold(
        (failure) => Resource.error(failure),
        (data) => Resource.success(data),
      );

  bool get isLoading => this is ResourceLoading<T>;
  bool get isSuccess => this is ResourceSuccess<T>;
  bool get isError => this is ResourceError<T>;

  T? get dataOrNull => switch (this) {
        ResourceSuccess<T>(:final data) => data,
        _ => null,
      };

  Failure? get failureOrNull => switch (this) {
        ResourceError<T>(:final failure) => failure,
        _ => null,
      };

  /// Exhaustive fold over the three states.
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) =>
      switch (this) {
        ResourceLoading<T>() => loading(),
        ResourceSuccess<T>(:final data) => success(data),
        ResourceError<T>(:final failure) => error(failure),
      };

  Resource<R> map<R>(R Function(T data) transform) => switch (this) {
        ResourceLoading<T>() => Resource<R>.loading(),
        ResourceSuccess<T>(:final data, :final message, :final statusCode, :final meta) =>
          Resource<R>.success(
            transform(data),
            message: message,
            statusCode: statusCode,
            meta: meta,
          ),
        ResourceError<T>(:final failure) => Resource<R>.error(failure),
      };

  /// `Right(data)` on success, `Left(failure)` on error. Loading has no
  /// equivalent, so it becomes an [UnknownFailure].
  Either<Failure, T> toEither() => switch (this) {
        ResourceSuccess<T>(:final data) => right(data),
        ResourceError<T>(:final failure) => left(failure),
        ResourceLoading<T>() =>
          left(const UnknownFailure('Resource is still loading')),
      };

  /// Bridge to the UI state type used by notifiers.
  RequestState<T> toRequestState() => switch (this) {
        ResourceLoading<T>() => const RequestLoading(),
        ResourceSuccess<T>(:final data) => RequestSuccess(data),
        ResourceError<T>(:final failure) => RequestFailure(failure),
      };
}

final class ResourceLoading<T> extends Resource<T> {
  const ResourceLoading();
}

final class ResourceSuccess<T> extends Resource<T> {
  const ResourceSuccess(
    this.data, {
    this.message,
    this.statusCode = StatusCode.ok,
    this.meta = const {},
  });

  final T data;

  /// Optional server / UI message (e.g. "Saved").
  final String? message;
  final int? statusCode;

  /// Extra envelope data such as pagination (`{'page': 2, 'hasMore': true}`).
  final Map<String, Object?> meta;
}

final class ResourceError<T> extends Resource<T> {
  const ResourceError(this.failure);

  final Failure failure;

  String get message => failure.message;
  int? get statusCode => failure.statusCode;
  String? get code => failure.code;
}
