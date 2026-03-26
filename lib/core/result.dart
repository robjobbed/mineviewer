sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(message: final m) => m,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(String message, Object? error) failure,
  }) =>
      switch (this) {
        Success(value: final v) => success(v),
        Failure(message: final m, error: final e) => failure(m, e),
      };
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, {this.error});
}
