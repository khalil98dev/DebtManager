library;

sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;

  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is FailureResult<T>;

  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    FailureResult() => null,
  };

  /// The failure cause if this is a [FailureResult], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    FailureResult(:final failure) => failure,
  };

  /// Pattern-matches over the result branches.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) => switch (this) {
    Success(:final data) => success(data),
    FailureResult(failure: final f) => failure(f),
  };
}

/// A successful outcome holding a [data] value of type [T].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Result.success($data)';
}

/// A failed outcome holding a [failure].
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FailureResult<T> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Result.failure($failure)';
}

/// Base sealed class representing application-level failures.
sealed class Failure {
  const Failure({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure &&
          other.runtimeType == runtimeType &&
          other.message == message &&
          other.cause == cause);

  @override
  int get hashCode => Object.hash(runtimeType, message, cause);

  @override
  String toString() => '$runtimeType(message: $message, cause: $cause)';
}

/// Failure when a requested entity or resource is not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.cause,
    this.entityType,
    this.entityId,
  });

  final String? entityType;
  final Object? entityId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotFoundFailure &&
          other.message == message &&
          other.entityType == entityType &&
          other.entityId == entityId &&
          other.cause == cause);

  @override
  int get hashCode => Object.hash(super.hashCode, entityType, entityId);
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.cause});
}

final class ConflictFailure extends Failure {
  const ConflictFailure({required super.message, super.cause});
}

final class RepositoryFailure extends Failure {
  const RepositoryFailure({required super.message, super.cause});
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.cause});
}

final class AuthorizationFailure extends Failure {
  const AuthorizationFailure({required super.message, super.cause});
}
