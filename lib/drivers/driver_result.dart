import '../core/result.dart';

enum DriverErrorType {
  connectionRefused,
  timeout,
  authRequired,
  parseError,
  unsupported,
  unknown;
}

typedef DriverResult<T> = Result<T>;

class DriverFailure<T> extends Failure<T> {
  final DriverErrorType type;
  const DriverFailure(
    super.message, {
    super.error,
    this.type = DriverErrorType.unknown,
  });
}
