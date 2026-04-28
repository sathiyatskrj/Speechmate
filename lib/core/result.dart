/// Functional Result type — eliminates null returns and silent failures.
/// Used by staff/principal engineers at FAANG to enforce explicit error handling.
///
/// Usage:
/// ```dart
/// final result = await service.doSomething();
/// result.when(
///   success: (data) => setState(() => _data = data),
///   failure: (error) => showSnackbar(error),
/// );
/// ```
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, [Object? exception]) = Failure<T>;

  /// Pattern match on success/failure
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final message) => failure(message),
    };
  }

  /// Get value or null
  T? get valueOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// Get value or throw
  T get valueOrThrow => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>(:final message) => throw StateError(message),
  };

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? exception;
  const Failure(this.message, [this.exception]);
}
